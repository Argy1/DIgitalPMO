from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator


class PatientProfileCreate(BaseModel):
    date_of_birth: date
    gender: str
    faskes_name: str
    doctor_name: str
    tb_type: str = "TB Paru"
    treatment_start_date: date
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

    @field_validator("tb_type")
    @classmethod
    def _validate_tb_type(cls, v: str) -> str:
        if v not in ("TB Paru", "TB Ekstra Paru", "TB RO"):
            raise ValueError("Tipe TB tidak valid.")
        return v


class PatientProfileUpdate(BaseModel):
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    faskes_name: Optional[str] = None
    doctor_name: Optional[str] = None
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
    tb_type: str
    treatment_start_date: date
    current_phase: str
    phase_updated_at: Optional[datetime] = None
    treatment_end_date: Optional[date] = None
    weight_kg: Optional[float] = None
    address: Optional[str] = None
    is_treatment_complete: bool
    is_hospitalized: bool
    is_pregnant: bool
    data_confirmed_by_patient: bool
    created_at: datetime
    updated_at: datetime
