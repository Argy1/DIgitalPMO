import io
import logging
from calendar import monthrange
from datetime import datetime
from typing import List, Optional

logger = logging.getLogger(__name__)

# ── ReportLab imports (optional dependency) ───────────────────────────────────
try:
    from reportlab.graphics.charts.barcharts import VerticalBarChart
    from reportlab.graphics.shapes import Drawing, String as RLString
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.platypus import (
        HRFlowable,
        Paragraph,
        SimpleDocTemplate,
        Spacer,
        Table,
        TableStyle,
    )
    _REPORTLAB_AVAILABLE = True
except ImportError:
    _REPORTLAB_AVAILABLE = False
    logger.warning("reportlab not installed. PDF generation will be unavailable.")

# ── Color palette ─────────────────────────────────────────────────────────────
_PRIMARY = colors.HexColor("#1565C0")   # deep blue
_SUCCESS = colors.HexColor("#2E7D32")   # dark green
_WARNING = colors.HexColor("#F57F17")   # amber
_DANGER = colors.HexColor("#C62828")    # dark red
_LIGHT = colors.HexColor("#F5F5F5")     # background
_GREY = colors.HexColor("#757575")


def _month_name_id(month: int) -> str:
    names = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember",
    ]
    return names[month - 1]


class PdfService:
    def generate_monthly_pdf(
        self,
        *,
        patient_name: str,
        year: int,
        month: int,
        adherence_percentage: float,
        total_scheduled: int,
        confirmed_doses: int,
        missed_doses: int,
        late_doses: int,
        daily_adherence: List[dict],      # [{"day": 1, "status": "confirmed"|"missed"|"pending"}]
        weekly_symptoms: List[dict],      # [{"week": 1, "cough": x, "appetite": x, "energy": x}]
        side_effects_summary: Optional[dict],
        ai_summary: Optional[str],
        ai_recommendation,                # str or list of str
    ) -> bytes:
        if not _REPORTLAB_AVAILABLE:
            raise RuntimeError(
                "reportlab is not installed. "
                "Run: pip install reportlab"
            )

        buf = io.BytesIO()
        doc = SimpleDocTemplate(
            buf,
            pagesize=A4,
            rightMargin=2 * cm,
            leftMargin=2 * cm,
            topMargin=2 * cm,
            bottomMargin=2 * cm,
        )

        styles = getSampleStyleSheet()
        story = []

        # ── Header ────────────────────────────────────────────────────────────
        header_style = ParagraphStyle(
            "header",
            fontSize=20,
            textColor=_PRIMARY,
            spaceAfter=4,
            fontName="Helvetica-Bold",
        )
        sub_style = ParagraphStyle(
            "sub",
            fontSize=11,
            textColor=_GREY,
            spaceAfter=2,
        )
        body_style = ParagraphStyle(
            "body",
            fontSize=10,
            spaceAfter=6,
            leading=14,
        )
        bold_style = ParagraphStyle(
            "bold_body",
            fontSize=10,
            fontName="Helvetica-Bold",
            spaceAfter=4,
        )
        section_style = ParagraphStyle(
            "section",
            fontSize=12,
            fontName="Helvetica-Bold",
            textColor=_PRIMARY,
            spaceBefore=12,
            spaceAfter=6,
        )

        story.append(Paragraph("DigitalPMO", header_style))
        story.append(Paragraph("Laporan Bulanan Kepatuhan Pengobatan TB", sub_style))
        story.append(HRFlowable(width="100%", thickness=2, color=_PRIMARY, spaceAfter=8))

        story.append(Paragraph(f"<b>Nama Pasien:</b> {patient_name}", body_style))
        story.append(
            Paragraph(
                f"<b>Periode:</b> {_month_name_id(month)} {year}",
                body_style,
            )
        )
        story.append(Spacer(1, 0.3 * cm))

        # ── Summary stats ─────────────────────────────────────────────────────
        story.append(Paragraph("RINGKASAN KEPATUHAN", section_style))

        adh_color = (
            _SUCCESS if adherence_percentage >= 80
            else _WARNING if adherence_percentage >= 50
            else _DANGER
        )
        adh_hex = adh_color.hexval() if hasattr(adh_color, "hexval") else "#000000"

        summary_data = [
            ["Metrik", "Nilai"],
            ["Persentase Kepatuhan", f"{adherence_percentage:.1f}%"],
            ["Total Jadwal", str(total_scheduled)],
            ["Dosis Dikonfirmasi", str(confirmed_doses)],
            ["Dosis Terlewat", str(missed_doses)],
            ["Dosis Terlambat", str(late_doses)],
        ]
        summary_table = Table(summary_data, colWidths=[8 * cm, 6 * cm])
        summary_table.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), _PRIMARY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [_LIGHT, colors.white]),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                ("ALIGN", (1, 0), (1, -1), "CENTER"),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ])
        )
        story.append(summary_table)
        story.append(Spacer(1, 0.4 * cm))

        # ── Adherence chart ───────────────────────────────────────────────────
        if daily_adherence:
            story.append(Paragraph("GRAFIK KEPATUHAN MINGGUAN", section_style))
            story.append(self._build_adherence_chart(daily_adherence, year, month))
            story.append(Spacer(1, 0.4 * cm))

        # ── Weekly symptom table ──────────────────────────────────────────────
        if weekly_symptoms:
            story.append(Paragraph("TABEL GEJALA MINGGUAN", section_style))
            sym_data = [["Minggu", "Skala Batuk", "Nafsu Makan", "Energi"]]
            for w in weekly_symptoms:
                sym_data.append([
                    f"Minggu {w['week']}",
                    f"{w['cough']:.1f}" if w.get("cough") is not None else "-",
                    f"{w['appetite']:.1f}" if w.get("appetite") is not None else "-",
                    f"{w['energy']:.1f}" if w.get("energy") is not None else "-",
                ])
            sym_table = Table(sym_data, colWidths=[4 * cm, 4 * cm, 4 * cm, 4 * cm])
            sym_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, 0), _PRIMARY),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [_LIGHT, colors.white]),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                    ("ALIGN", (1, 0), (-1, -1), "CENTER"),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ])
            )
            story.append(sym_table)
            story.append(Spacer(1, 0.4 * cm))

        # ── Side effects summary ──────────────────────────────────────────────
        if side_effects_summary:
            story.append(Paragraph("EFEK SAMPING", section_style))
            se_data = [["Efek Samping", "Jumlah Kejadian"]]
            for name, count in sorted(side_effects_summary.items(), key=lambda x: -x[1]):
                se_data.append([name, str(count)])
            se_table = Table(se_data, colWidths=[10 * cm, 4 * cm])
            se_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, 0), _WARNING),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [_LIGHT, colors.white]),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                    ("ALIGN", (1, 0), (1, -1), "CENTER"),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ])
            )
            story.append(se_table)
            story.append(Spacer(1, 0.4 * cm))

        # ── AI summary ────────────────────────────────────────────────────────
        if ai_summary:
            story.append(Paragraph("RINGKASAN AI", section_style))
            story.append(Paragraph(ai_summary, body_style))
            story.append(Spacer(1, 0.3 * cm))

        # ── AI recommendation ─────────────────────────────────────────────────
        if ai_recommendation:
            story.append(Paragraph("REKOMENDASI", section_style))
            recs = (
                ai_recommendation
                if isinstance(ai_recommendation, list)
                else [ai_recommendation]
            )
            for rec in recs:
                story.append(Paragraph(f"• {rec}", body_style))
            story.append(Spacer(1, 0.3 * cm))

        # ── Footer ────────────────────────────────────────────────────────────
        story.append(HRFlowable(width="100%", thickness=1, color=_GREY, spaceBefore=8))
        footer_style = ParagraphStyle(
            "footer",
            fontSize=8,
            textColor=_GREY,
            spaceAfter=2,
        )
        story.append(
            Paragraph(
                f"Dibuat pada: {datetime.now().strftime('%d %B %Y %H:%M')} WIB",
                footer_style,
            )
        )
        story.append(
            Paragraph(
                "Disclaimer: Laporan ini dibuat secara otomatis oleh sistem DigitalPMO "
                "dan tidak menggantikan penilaian klinis profesional medis. "
                "Selalu konsultasikan kondisi kesehatan Anda dengan dokter atau tenaga kesehatan.",
                footer_style,
            )
        )

        doc.build(story)
        return buf.getvalue()

    # ── Adherence chart ───────────────────────────────────────────────────────

    def _build_adherence_chart(
        self, daily_adherence: List[dict], year: int, month: int
    ) -> "Drawing":
        _, last_day = monthrange(year, month)
        # Group into 4–5 weeks, compute weekly adherence %
        weeks: dict[int, list] = {1: [], 2: [], 3: [], 4: [], 5: []}
        for entry in daily_adherence:
            day = entry.get("day", 1)
            week_num = min(((day - 1) // 7) + 1, 5)
            weeks[week_num].append(entry.get("status") == "confirmed")

        labels = []
        values = []
        for w in range(1, 6):
            days_in_week = weeks[w]
            if not days_in_week:
                continue
            pct = (sum(days_in_week) / len(days_in_week)) * 100
            labels.append(f"Minggu {w}")
            values.append(round(pct, 1))

        if not values:
            return Drawing(400, 10)

        drawing = Drawing(400, 180)
        chart = VerticalBarChart()
        chart.x = 50
        chart.y = 30
        chart.width = 320
        chart.height = 130
        chart.data = [values]
        chart.categoryAxis.categoryNames = labels
        chart.categoryAxis.labels.boxAnchor = "ne"
        chart.categoryAxis.labels.angle = 0
        chart.categoryAxis.labels.fontSize = 9
        chart.valueAxis.valueMin = 0
        chart.valueAxis.valueMax = 100
        chart.valueAxis.valueStep = 25
        chart.valueAxis.labels.fontSize = 9
        chart.bars[0].fillColor = _PRIMARY
        chart.bars[0].strokeColor = colors.white

        title = RLString(
            200, 170, "Kepatuhan per Minggu (%)",
            fontSize=10, fontName="Helvetica-Bold",
            textAnchor="middle", fillColor=_PRIMARY,
        )
        drawing.add(chart)
        drawing.add(title)
        return drawing


pdf_service = PdfService()
