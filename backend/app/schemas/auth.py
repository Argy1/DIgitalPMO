import re
from typing import Optional

from pydantic import BaseModel, field_validator

from app.schemas.user import UserResponse


def _normalize_phone(value: str) -> str:
    cleaned = re.sub(r"\D", "", value)
    if cleaned.startswith("62") and len(cleaned) > 10:
        cleaned = f"0{cleaned[2:]}"
    if not (10 <= len(cleaned) <= 15):
        raise ValueError("Nomor telepon tidak valid (10-15 digit).")
    return cleaned


class RegisterRequest(BaseModel):
    name: str
    phone: str
    password: str

    @field_validator("phone")
    @classmethod
    def _clean_phone(cls, v: str) -> str:
        return _normalize_phone(v)

    @field_validator("password")
    @classmethod
    def _check_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password minimal 6 karakter.")
        return v


class RegisterResponse(BaseModel):
    message: str
    phone_masked: str
    dev_otp: Optional[str] = None
    skip_otp: bool = False


class LoginRequest(BaseModel):
    phone: str
    password: str
    fcm_token: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def _clean_phone(cls, v: str) -> str:
        return _normalize_phone(v)


class OTPVerify(BaseModel):
    phone: str
    otp: str

    @field_validator("phone")
    @classmethod
    def _clean_phone(cls, v: str) -> str:
        return _normalize_phone(v)


class OTPRequest(BaseModel):
    phone_number: str
    full_name: str = ""

    @field_validator("phone_number")
    @classmethod
    def _clean_phone_number(cls, v: str) -> str:
        return _normalize_phone(v)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def _check_new_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password baru minimal 8 karakter.")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password baru harus mengandung angka.")
        if not any(c.isalpha() for c in v):
            raise ValueError("Password baru harus mengandung huruf.")
        return v


class UpdateUserRequest(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
