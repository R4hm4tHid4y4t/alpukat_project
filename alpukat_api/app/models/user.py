from datetime import datetime
from typing import Optional, List
from sqlalchemy import String, SmallInteger, Text, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nama: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="pengguna")
    status_verifikasi: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    foto_profil: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True, onupdate=datetime.utcnow)

    # Relationships
    otp_list: Mapped[List["OtpVerifikasi"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    profil: Mapped[Optional["ProfilPengguna"]] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    hasil_deteksi_list: Mapped[List["HasilDeteksi"]] = relationship(
        back_populates="user"
    )
    riwayat_list: Mapped[List["RiwayatDeteksi"]] = relationship(
        back_populates="user"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "nama": self.nama,
            "email": self.email,
            "role": self.role,
            "status_verifikasi": self.status_verifikasi,
            "foto_profil": self.foto_profil,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} role={self.role}>"


class OtpVerifikasi(Base):
    __tablename__ = "otp_verifikasi"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    kode_otp: Mapped[str] = mapped_column(String(6), nullable=False)
    tipe: Mapped[str] = mapped_column(String(20), nullable=False)  # verifikasi | reset
    status_digunakan: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    expired_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="otp_list")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "tipe": self.tipe,
            "status_digunakan": self.status_digunakan,
            "expired_at": self.expired_at.isoformat() if self.expired_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self) -> str:
        return f"<OtpVerifikasi id={self.id} user_id={self.user_id} tipe={self.tipe}>"


class ProfilPengguna(Base):
    __tablename__ = "profil_pengguna"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    no_telepon: Mapped[Optional[str]] = mapped_column(String(15), nullable=True)
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True, onupdate=datetime.utcnow
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="profil")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "bio": self.bio,
            "no_telepon": self.no_telepon,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self) -> str:
        return f"<ProfilPengguna id={self.id} user_id={self.user_id}>"
