from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional
import re


class RegisterRequest(BaseModel):
    nama: str
    email: EmailStr
    password: str
    confirm_password: str

    @field_validator("nama")
    @classmethod
    def validate_nama(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Nama minimal 2 karakter")
        if len(v) > 100:
            raise ValueError("Nama maksimal 100 karakter")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password minimal 8 karakter")
        if not re.search(r"[A-Za-z]", v):
            raise ValueError("Password harus mengandung huruf")
        if not re.search(r"\d", v):
            raise ValueError("Password harus mengandung angka")
        return v

    @model_validator(mode="after")
    def passwords_match(self) -> "RegisterRequest":
        if self.password != self.confirm_password:
            raise ValueError("Password dan konfirmasi password tidak cocok")
        return self


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class OtpVerifyRequest(BaseModel):
    user_id: int
    kode_otp: str

    @field_validator("kode_otp")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        v = v.strip()
        if not v.isdigit() or len(v) != 6:
            raise ValueError("Kode OTP harus 6 digit angka")
        return v


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    kode_otp: str
    new_password: str
    confirm_password: str

    @field_validator("kode_otp")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        if not v.isdigit() or len(v) != 6:
            raise ValueError("Kode OTP harus 6 digit angka")
        return v

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password minimal 8 karakter")
        if not re.search(r"[A-Za-z]", v):
            raise ValueError("Password harus mengandung huruf")
        if not re.search(r"\d", v):
            raise ValueError("Password harus mengandung angka")
        return v

    @model_validator(mode="after")
    def passwords_match(self) -> "ResetPasswordRequest":
        if self.new_password != self.confirm_password:
            raise ValueError("Password dan konfirmasi tidak cocok")
        return self


class UserResponse(BaseModel):
    id: int
    nama: str
    email: str
    role: str
    status_verifikasi: int
    foto_profil: Optional[str] = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
