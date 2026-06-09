from datetime import date, datetime
from enum import Enum as PyEnum
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator, model_validator


# ── Pydantic enums ────────────────────────────────────────────────────────────

class TBCategory(str, PyEnum):
    SO = "SO"
    RO = "RO"


class TBSOType(str, PyEnum):
    TB_PARU = "TB Paru"
    TB_OTAK = "TB Ekstra Paru - Otak"
    TB_TULANG = "TB Ekstra Paru - Tulang"
    TB_KULIT = "TB Ekstra Paru - Kulit"
    TB_KELENJAR = "TB Ekstra Paru - Kelenjar"
    TB_PLEURA = "TB Ekstra Paru - Pleura"
    TB_ABDOMINAL = "TB Ekstra Paru - Abdominal"
    TB_MILIER = "TB Ekstra Paru - Milier"


class TBROType(str, PyEnum):
    MDR = "MDR"
    XDR = "XDR"
    RR = "RR"


class MedicationTypeEnum(str, PyEnum):
    FDC = "FDC"
    KOMBINASI = "Kombinasi"


class FDCTypeEnum(str, PyEnum):
    FDC = "FDC"
    KOMBIPAK = "Kombipak"


_VALID_CUSTOM_MEDS = {"R", "H", "Z", "E"}


# ── PatientProfileCreate ──────────────────────────────────────────────────────

class PatientProfileCreate(BaseModel):
    date_of_birth: date
    gender: str
    faskes_name: str
    doctor_name: str

    tb_category: TBCategory = TBCategory.SO
    tb_so_type: Optional[TBSOType] = TBSOType.TB_PARU
    tb_ro_type: Optional[TBROType] = None

    treatment_start_date: date
    treatment_duration_days: Optional[int] = None

    medication_type: Optional[MedicationTypeEnum] = None
    fdc_type: Optional[FDCTypeEnum] = None
    custom_medications: Optional[List[str]] = None

    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_pregnant: Optional[bool] = False

    @field_validator("treatment_start_date")
    @classmethod
    def _validate_start_date(cls, v: date) -> date:
        if v > date.today():
            raise ValueError("Tanggal mulai pengobatan tidak boleh di masa depan.")
        return v

    @field_validator("gender")
    @classmethod
    def _validate_gender(cls, v: str) -> str:
        if v not in ("laki-laki", "perempuan"):
            raise ValueError("Gender harus 'laki-laki' atau 'perempuan'.")
        return v

    @field_validator("treatment_duration_days")
    @classmethod
    def _validate_duration(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v < 42:
            raise ValueError("Durasi pengobatan minimal 42 hari (6 minggu).")
        return v

    @field_validator("custom_medications")
    @classmethod
    def _validate_custom_meds(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            invalid = set(v) - _VALID_CUSTOM_MEDS
            if invalid:
                raise ValueError(
                    f"Obat tidak valid: {sorted(invalid)}. "
                    f"Hanya boleh subset dari {sorted(_VALID_CUSTOM_MEDS)}."
                )
        return v

    @model_validator(mode="after")
    def _validate_cross_fields(self) -> "PatientProfileCreate":
        # TB category / type consistency
        if self.tb_category == TBCategory.SO:
            if not self.tb_so_type:
                raise ValueError(
                    "tb_so_type wajib diisi untuk TB Sensitif Obat (SO)."
                )
            self.tb_ro_type = None
        else:  # RO
            if not self.tb_ro_type:
                raise ValueError(
                    "tb_ro_type wajib diisi untuk TB Resisten Obat (RO)."
                )
            self.tb_so_type = None

        # Medication type consistency
        if self.medication_type == MedicationTypeEnum.FDC:
            if not self.fdc_type:
                raise ValueError(
                    "fdc_type wajib diisi jika medication_type adalah FDC."
                )
            self.custom_medications = None
        elif self.medication_type == MedicationTypeEnum.KOMBINASI:
            if not self.custom_medications:
                raise ValueError(
                    "custom_medications wajib diisi dan tidak boleh kosong "
                    "jika medication_type adalah Kombinasi."
                )
            self.fdc_type = None

        return self


# ── PatientProfileUpdate ──────────────────────────────────────────────────────

class PatientProfileUpdate(BaseModel):
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    faskes_name: Optional[str] = None
    doctor_name: Optional[str] = None
    tb_category: Optional[TBCategory] = None
    tb_so_type: Optional[TBSOType] = None
    tb_ro_type: Optional[TBROType] = None
    treatment_duration_days: Optional[int] = None
    medication_type: Optional[MedicationTypeEnum] = None
    fdc_type: Optional[FDCTypeEnum] = None
    custom_medications: Optional[List[str]] = None
    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_pregnant: Optional[bool] = None
    data_confirmed_by_patient: Optional[bool] = None

    @field_validator("treatment_duration_days")
    @classmethod
    def _validate_duration(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v < 42:
            raise ValueError("Durasi pengobatan minimal 42 hari (6 minggu).")
        return v

    @field_validator("custom_medications")
    @classmethod
    def _validate_custom_meds(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            invalid = set(v) - _VALID_CUSTOM_MEDS
            if invalid:
                raise ValueError(
                    f"Obat tidak valid: {sorted(invalid)}. "
                    f"Hanya boleh subset dari {sorted(_VALID_CUSTOM_MEDS)}."
                )
        return v

    @model_validator(mode="after")
    def _validate_cross_fields_partial(self) -> "PatientProfileUpdate":
        """Only validate cross-field rules for fields explicitly provided."""
        explicitly_set = self.model_fields_set

        if "medication_type" in explicitly_set:
            if self.medication_type == MedicationTypeEnum.FDC:
                if "fdc_type" in explicitly_set and not self.fdc_type:
                    raise ValueError(
                        "fdc_type wajib diisi jika medication_type adalah FDC."
                    )
            elif self.medication_type == MedicationTypeEnum.KOMBINASI:
                if "custom_medications" in explicitly_set and not self.custom_medications:
                    raise ValueError(
                        "custom_medications wajib diisi jika medication_type adalah Kombinasi."
                    )

        return self


# ── HospitalizedUpdate ────────────────────────────────────────────────────────

class HospitalizedUpdate(BaseModel):
    is_hospitalized: bool


# ── PatientProfileResponse ────────────────────────────────────────────────────

class PatientProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    date_of_birth: date
    gender: str
    faskes_name: str
    doctor_name: str

    tb_category: str
    tb_so_type: Optional[str] = None
    tb_ro_type: Optional[str] = None

    treatment_start_date: date
    current_phase: str
    phase_updated_at: Optional[datetime] = None
    treatment_duration_days: Optional[int] = None
    treatment_end_date: Optional[date] = None

    medication_type: Optional[str] = None
    fdc_type: Optional[str] = None
    custom_medications: Optional[List[str]] = None

    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_treatment_complete: bool
    is_hospitalized: bool
    is_pregnant: bool
    data_confirmed_by_patient: bool
    created_at: datetime
    updated_at: datetime
