import json
import logging
import re
import time
from typing import Generator, List, Optional

import anthropic

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Project standardises on Haiku 4.5 — it supports vision and is cost-efficient.
CHAT_MODEL = "claude-haiku-4-5-20251001"
VISION_MODEL = "claude-haiku-4-5-20251001"

_MED_NAMES = {
    "R": "Rifampicin (kapsul merah-oranye)",
    "H": "Isoniazid (tablet putih kecil)",
    "Z": "Pirazinamid (tablet putih besar)",
    "E": "Etambutol (tablet putih oval)",
}

TB_SYSTEM_PROMPT = """Kamu adalah asisten kesehatan AI untuk pasien TB di Indonesia. \
Berikan informasi yang akurat, empati, dan selalu sarankan konsultasi dengan dokter untuk hal-hal medis serius. \
Gunakan bahasa Indonesia yang mudah dipahami. \
Fokus pada edukasi tentang pengobatan TB, pentingnya kepatuhan minum obat, dan dukungan emosional untuk pasien. \
Jangan pernah merekomendasikan menghentikan pengobatan atau mengubah dosis tanpa konsultasi dokter."""


def build_medication_verification_prompt(
    medication_type: Optional[str] = None,
    fdc_type: Optional[str] = None,
    expected_tablet_count: Optional[int] = None,
    custom_medications: Optional[List[str]] = None,
    phase: Optional[str] = None,
) -> str:
    phase = phase or "intensive"
    medication_type = medication_type or "FDC"

    if medication_type == "FDC":
        fdc_label = "4FDC" if phase == "intensive" else "2FDC"
        tablet_info = f"{expected_tablet_count} tablet" if expected_tablet_count else "tablet"
        medication_desc = f"{tablet_info} {fdc_label} ({fdc_type or 'FDC'})"
        count_instruction = (
            f"Hitung jumlah tablet: harus ada tepat {expected_tablet_count} tablet"
            if expected_tablet_count
            else "Pastikan tablet FDC terlihat jelas"
        )
        count_field = expected_tablet_count if expected_tablet_count else "null"
    else:
        meds_display = ", ".join(
            [_MED_NAMES.get(m, m) for m in (custom_medications or [])]
        )
        medication_desc = f"Obat kombinasi: {meds_display}" if meds_display else "Obat kombinasi"
        count_instruction = (
            f"Pastikan semua obat berikut terlihat: {meds_display}"
            if meds_display
            else "Pastikan semua obat terlihat jelas"
        )
        count_field = "null"

    phase_label = "Intensif" if phase == "intensive" else "Lanjutan"

    return f"""Kamu adalah AI verifikasi kepatuhan minum obat TB untuk aplikasi DigitalPMO.

TUGAS: Verifikasi apakah foto ini menunjukkan pasien sedang memegang obat TB yang benar sesuai jadwal.

OBAT YANG DIHARAPKAN:
- Jenis: {medication_desc}
- Fase pengobatan: {phase_label}
- {count_instruction}

KRITERIA VERIFIKASI:
1. Ada tablet/kapsul obat yang terlihat jelas di foto
2. Obat ada di tangan/telapak tangan (bukan di meja atau kemasan)
3. {"Jumlah tablet = " + str(expected_tablet_count) if expected_tablet_count else "Obat yang dipilih dokter terlihat"}
4. Foto terlihat real-time (bukan foto obat dari internet atau gambar)

RESPONS dalam format JSON:
{{
  "is_valid": true/false,
  "confidence": 0-100,
  "detected_objects": ["pill", "tablet", ...],
  "tablets_detected": angka atau null,
  "tablets_expected": {count_field},
  "count_match": true/false/null,
  "issues": ["list masalah jika ada"],
  "rejection_reason": "null atau alasan penolakan dalam Bahasa Indonesia"
}}

PENTING:
- Jika tidak yakin (confidence < 60), set is_valid = false
- Jangan pernah verify foto yang jelas bukan obat
- Jika foto blur atau pencahayaan buruk, set is_valid = false
- rejection_reason harus dalam Bahasa Indonesia yang jelas untuk pasien"""


class AIService:
    def __init__(self):
        self._client = None

    @property
    def client(self) -> anthropic.Anthropic:
        if self._client is None:
            self._client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        return self._client

    # ── Helpers ───────────────────────────────────────────────────────────────

    @staticmethod
    def _strip_data_uri(photo_base64: str) -> str:
        data = photo_base64.strip()
        if data.startswith("data:") and "," in data:
            return data.split(",", 1)[1]
        return data

    @staticmethod
    def _parse_json(text: str) -> dict:
        cleaned = text.strip()
        if cleaned.startswith("```"):
            cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
            cleaned = re.sub(r"\s*```$", "", cleaned)
        match = re.search(r"\{.*\}", cleaned, re.DOTALL)
        if match:
            cleaned = match.group(0)
        return json.loads(cleaned)

    @staticmethod
    def _build_messages(message: str, history: List[dict]) -> List[dict]:
        messages: List[dict] = []
        for item in history or []:
            role = item.get("role", "user")
            content = item.get("content", "")
            if role in ("user", "assistant") and content:
                messages.append({"role": role, "content": content})
        messages.append({"role": "user", "content": message})
        return messages

    # ── Photo verification ────────────────────────────────────────────────────

    def verify_medication_photo(
        self,
        photo_base64: str,
        medication_type: Optional[str] = None,
        fdc_type: Optional[str] = None,
        expected_tablet_count: Optional[int] = None,
        custom_medications: Optional[List[str]] = None,
        phase: Optional[str] = None,
    ) -> dict:
        """Run AI vision verification on a medication photo. Returns parsed result."""
        start = time.perf_counter()
        b64 = self._strip_data_uri(photo_base64)
        prompt = build_medication_verification_prompt(
            medication_type=medication_type,
            fdc_type=fdc_type,
            expected_tablet_count=expected_tablet_count,
            custom_medications=custom_medications,
            phase=phase,
        )
        try:
            response = self.client.messages.create(
                model=VISION_MODEL,
                max_tokens=400,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": "image/jpeg",
                                    "data": b64,
                                },
                            },
                            {"type": "text", "text": prompt},
                        ],
                    }
                ],
            )
            parsed = self._parse_json(response.content[0].text)
            elapsed_ms = round((time.perf_counter() - start) * 1000, 1)
            rejection = parsed.get("rejection_reason")
            if isinstance(rejection, str) and rejection.lower() in ("null", "none", ""):
                rejection = None
            return {
                "is_valid": bool(parsed.get("is_valid", False)),
                "confidence": float(parsed.get("confidence", 0)),
                "detected_objects": parsed.get("detected_objects", []),
                "tablets_detected": parsed.get("tablets_detected"),
                "tablets_expected": parsed.get("tablets_expected"),
                "count_match": parsed.get("count_match"),
                "issues": parsed.get("issues", []),
                "rejection_reason": rejection,
                "raw": parsed,
                "model": VISION_MODEL,
                "processing_time_ms": elapsed_ms,
            }
        except (anthropic.APIError, json.JSONDecodeError, KeyError, IndexError) as exc:
            logger.error("Photo verification failed: %s", exc)
            elapsed_ms = round((time.perf_counter() - start) * 1000, 1)
            return {
                "is_valid": None,
                "confidence": 0.0,
                "detected_objects": [],
                "tablets_detected": None,
                "tablets_expected": None,
                "count_match": None,
                "issues": [],
                "rejection_reason": "Verifikasi otomatis gagal. Foto akan ditinjau manual.",
                "raw": {"error": str(exc)},
                "model": VISION_MODEL,
                "processing_time_ms": elapsed_ms,
            }

    # ── Chat ──────────────────────────────────────────────────────────────────

    def build_chat_system_prompt(self, patient_name: str, ctx: dict) -> str:
        ctx = ctx or {}
        meds = ctx.get("current_meds", "-")
        if isinstance(meds, (list, tuple)):
            meds = ", ".join(str(m) for m in meds) or "-"
        return f"""Kamu adalah PMO Digital, asisten AI pendamping pasien TB bernama {patient_name}.

Konteks pasien:
- Hari ke-{ctx.get('day_number', '?')} dari 180
- Fase: {ctx.get('phase', 'intensive')}
- Streak: {ctx.get('streak', 0)} hari
- Obat: {meds}
- Gejala terakhir: {ctx.get('last_symptoms', '-')}
- Efek samping terakhir: {ctx.get('recent_side_effects', '-')}

Tugas kamu:
1. Berikan edukasi akurat tentang TB
2. Jelaskan efek samping obat
3. Berikan motivasi dan dukungan
4. JANGAN berikan diagnosis medis
5. Sarankan ke dokter jika gejala berat

Gaya bahasa: hangat, supportif, mudah dipahami, Bahasa Indonesia.
Response max 150 kata kecuali perlu penjelasan panjang."""

    def chat_stream(
        self, message: str, history: List[dict], system_prompt: str
    ) -> Generator[str, None, None]:
        """Stream a chat completion token-by-token."""
        messages = self._build_messages(message, history)
        try:
            with self.client.messages.stream(
                model=CHAT_MODEL,
                max_tokens=1024,
                system=system_prompt,
                messages=messages,
            ) as stream:
                for text in stream.text_stream:
                    yield text
        except anthropic.APIError as exc:
            logger.error("Anthropic streaming error: %s", exc)
            yield (
                "Maaf, saya sedang tidak dapat merespons saat ini. "
                "Silakan coba lagi nanti atau hubungi petugas kesehatan Anda."
            )

    def chat(self, message: str, history: List[dict], system_prompt: str = None) -> str:
        try:
            response = self.client.messages.create(
                model=CHAT_MODEL,
                max_tokens=1024,
                system=system_prompt or TB_SYSTEM_PROMPT,
                messages=self._build_messages(message, history),
            )
            return response.content[0].text
        except anthropic.APIError as exc:
            logger.error("Anthropic API error in chat: %s", exc)
            return (
                "Maaf, saya sedang tidak dapat merespons saat ini. "
                "Silakan coba lagi nanti atau hubungi petugas kesehatan Anda."
            )

    # ── Education ─────────────────────────────────────────────────────────────

    def generate_education_content(self, trigger_type: str, patient_data: dict) -> dict:
        """Generate contextual TB education content based on a trigger."""
        patient_data = patient_data or {}
        prompt = f"""Buat konten edukasi TB yang singkat dan relevan untuk pasien.

Trigger: {trigger_type}
Konteks pasien:
- Fase: {patient_data.get('phase', '-')}
- Hari ke-{patient_data.get('day_number', '-')}
- Gejala terakhir: {patient_data.get('last_symptoms', '-')}
- Efek samping: {patient_data.get('recent_side_effects', '-')}

Respond HANYA dalam JSON:
{{
  "title": "judul singkat",
  "body": "isi edukasi 2-4 paragraf, Bahasa Indonesia, hangat dan mudah dipahami",
  "category": "kategori edukasi"
}}"""
        try:
            response = self.client.messages.create(
                model=CHAT_MODEL,
                max_tokens=800,
                system=TB_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": prompt}],
            )
            parsed = self._parse_json(response.content[0].text)
            return {
                "title": parsed.get("title", "Edukasi TB"),
                "body": parsed.get("body", ""),
                "category": parsed.get("category", trigger_type),
                "trigger_type": trigger_type,
            }
        except (anthropic.APIError, json.JSONDecodeError, KeyError, IndexError) as exc:
            logger.error("Education generation failed: %s", exc)
            return {
                "title": "Tetap Semangat Menjalani Pengobatan TB",
                "body": (
                    "Pengobatan TB membutuhkan kedisiplinan minum obat setiap hari. "
                    "Jangan berhenti meski sudah merasa sehat — kuman TB butuh waktu "
                    "untuk benar-benar hilang. Hubungi dokter atau PMO jika ada keluhan."
                ),
                "category": trigger_type,
                "trigger_type": trigger_type,
            }

    # ── Symptom assessment ────────────────────────────────────────────────────

    def assess_symptoms(self, symptom_data: dict) -> str:
        try:
            description = f"""
Pasien melaporkan gejala berikut:
- Skala batuk: {symptom_data.get('cough_scale', 'N/A')}/5
- Skala sesak napas: {symptom_data.get('breath_scale', 'N/A')}/5
- Skala nafsu makan: {symptom_data.get('appetite_scale', 'N/A')}/5
- Skala energi: {symptom_data.get('energy_scale', 'N/A')}/5
- Demam: {'Ya' if symptom_data.get('has_fever') else 'Tidak'}
- Suhu: {symptom_data.get('fever_temp', 'N/A')} °C
- Keringat malam: {'Ya' if symptom_data.get('has_night_sweats') else 'Tidak'}
- Berat badan: {symptom_data.get('weight_kg', 'N/A')} kg
- Catatan tambahan: {symptom_data.get('notes', '-')}

Berikan penilaian singkat tentang kondisi pasien dan saran yang perlu dilakukan. \
Jika ada gejala yang mengkhawatirkan, sarankan segera berkonsultasi dengan dokter.
"""
            response = self.client.messages.create(
                model=CHAT_MODEL,
                max_tokens=1024,
                system=TB_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": description}],
            )
            return response.content[0].text
        except anthropic.APIError as exc:
            logger.error("Anthropic API error in assess_symptoms: %s", exc)
            return (
                "Penilaian gejala tidak tersedia saat ini. "
                "Konsultasikan dengan dokter atau petugas kesehatan Anda."
            )

    # ── Reports ───────────────────────────────────────────────────────────────

    def generate_report_summary(self, report_data: dict) -> str:
        try:
            prompt = f"""
Buat ringkasan laporan bulanan pengobatan TB untuk bulan {report_data.get('report_month', 'N/A')}:

- Persentase kepatuhan: {report_data.get('adherence_percentage', 0):.1f}%
- Dosis terjadwal: {report_data.get('total_scheduled', 0)}
- Dosis terkonfirmasi: {report_data.get('confirmed_doses', 0)}
- Dosis terlewat: {report_data.get('missed_doses', 0)}
- Dosis terlambat: {report_data.get('late_doses', 0)}

Tuliskan ringkasan dalam 2-3 kalimat yang informatif dan suportif untuk pasien.
"""
            response = self.client.messages.create(
                model=CHAT_MODEL,
                max_tokens=1024,
                system=TB_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": prompt}],
            )
            return response.content[0].text
        except anthropic.APIError as exc:
            logger.error("Anthropic API error in generate_report_summary: %s", exc)
            adherence = report_data.get("adherence_percentage", 0)
            return (
                f"Laporan bulan {report_data.get('report_month', '')}: "
                f"Tingkat kepatuhan Anda adalah {adherence:.1f}%. "
                "Terus semangat menjalani pengobatan TB!"
            )

    def generate_recommendations(self, report_data: dict) -> List[str]:
        try:
            adherence = report_data.get("adherence_percentage", 0)
            prompt = f"""
Berdasarkan data pengobatan TB berikut, berikan 3-5 rekomendasi spesifik untuk pasien:
- Persentase kepatuhan: {adherence:.1f}%
- Dosis terkonfirmasi: {report_data.get('confirmed_doses', 0)}
- Dosis terlewat: {report_data.get('missed_doses', 0)}

Format: Berikan sebagai daftar poin singkat, satu rekomendasi per baris, dimulai dengan "-".
"""
            response = self.client.messages.create(
                model=CHAT_MODEL,
                max_tokens=1024,
                system=TB_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": prompt}],
            )
            text = response.content[0].text
            lines = [
                line.strip().lstrip("- ").strip()
                for line in text.split("\n")
                if line.strip().startswith("-")
            ]
            return lines if lines else [text]
        except anthropic.APIError as exc:
            logger.error("Anthropic API error in generate_recommendations: %s", exc)
            return self._default_recommendations(report_data)

    def _default_recommendations(self, report_data: dict) -> List[str]:
        adherence = report_data.get("adherence_percentage", 0)
        recs = ["Lanjutkan pengobatan TB sesuai jadwal yang ditentukan dokter."]
        if adherence < 80:
            recs.append(
                "Tingkatkan kepatuhan minum obat — konsistensi sangat penting untuk kesembuhan."
            )
        recs.append("Lakukan kontrol rutin ke faskes sesuai jadwal.")
        recs.append("Hubungi PMO atau dokter jika ada gejala baru atau efek samping.")
        return recs


ai_service = AIService()
