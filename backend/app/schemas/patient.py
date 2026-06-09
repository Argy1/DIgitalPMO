from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator


_TB_SO_TYPES = (
    "TB Paru",
    "TB Ekstra Paru - Otak",
    "TB Ekstra Paru - Tulang",
    "TB Ekstra Paru - Kulit",
    "TB Ekstra Paru - Kelenjar",
    "TB Ekstra Paru - Pleura",
    "TB Ekstra Paru - Abdominal",
    "TB Ekstra Paru - Milier",
)
_TB_RO_TYPES = ("MDR", "XDR", "RR")


class PatientProfileCreate(BaseModel):
    date_of_birth: date
    gender: str
    faskes_name: str
    doctor_name: str

    # Klasifikasi TB baru
    tb_category: str = "SO"               # "SO" atau "RO"
    tb_so_type: Optional[str] = "TB Paru"  # diisi jika SO
    tb_ro_type: Optional[str] = None       # diisi jika RO

    treatment_start_date: date
    # Durasi & end-date diisi manual oleh dokter (bukan auto-calculate)
    treatment_duration_days: Optional[int] = None

    # Jenis obat
    medication_type: Optional[str] = None  # "FDC" atau "Kombinasi"
    fdc_type: Optional[str] = None         # "FDC" atau "Kombipak"
    custom_medications: Optional[list[str]] = None

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

    @field_validator("tb_category")
    @classmethod
    def _validate_tb_category(cls, v: str) -> str:
        if v not in ("SO", "RO"):
            raise ValueError("Kategori TB harus 'SO' atau 'RO'.")
        return v

    @field_validator("tb_so_type")
    @classmethod
    def _validate_tb_so_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _TB_SO_TYPES:
            raise ValueError("Tipe TB SO tidak valid.")
        return v

    @field_validator("tb_ro_type")
    @classmethod
    def _validate_tb_ro_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _TB_RO_TYPES:
            raise ValueError("Tipe TB RO tidak valid.")
        return v


class PatientProfileUpdate(BaseModel):
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    faskes_name: Optional[str] = None
    doctor_name: Optional[str] = None
    tb_category: Optional[str] = None
    tb_so_type: Optional[str] = None
    tb_ro_type: Optional[str] = None
    treatment_duration_days: Optional[int] = None
    medication_type: Optional[str] = None
    fdc_type: Optional[str] = None
    custom_medications: Optional[list[str]] = None
    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_pregnant: Optional[bool] = None
    data_confirmed_by_patient: Optional[bool] = None


class HospitalizedUpdate(BaseModel):
    is_hospitalized: bool


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
    custom_medications: Optional[list[str]] = None
    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_treatment_complete: bool
    is_hospitalized: bool
    is_pregnant: bool
    data_confirmed_by_patient: bool
    created_at: datetime
    updated_at: datetime
