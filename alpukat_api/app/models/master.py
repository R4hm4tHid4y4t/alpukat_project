from datetime import datetime
from typing import Optional, List
from sqlalchemy import String, Text, DateTime, ForeignKey, Integer, DECIMAL, SmallInteger
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Varietas(Base):
    __tablename__ = "varietas"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nama_varietas: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    deskripsi: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gambar_referensi: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True, onupdate=datetime.utcnow
    )

    # Relationships
    hasil_deteksi_list: Mapped[List["HasilDeteksi"]] = relationship(
        back_populates="varietas"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "nama_varietas": self.nama_varietas,
            "deskripsi": self.deskripsi,
            "gambar_referensi": self.gambar_referensi,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self) -> str:
        return f"<Varietas id={self.id} nama={self.nama_varietas}>"


class TingkatKematangan(Base):
    __tablename__ = "tingkat_kematangan"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    label_kematangan: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    deskripsi: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ciri_visual: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True, onupdate=datetime.utcnow
    )

    # Relationships
    hasil_deteksi_list: Mapped[List["HasilDeteksi"]] = relationship(
        back_populates="kematangan"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "label_kematangan": self.label_kematangan,
            "deskripsi": self.deskripsi,
            "ciri_visual": self.ciri_visual,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self) -> str:
        return f"<TingkatKematangan id={self.id} label={self.label_kematangan}>"


class ModelCnn(Base):
    __tablename__ = "model_cnn"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    versi: Mapped[str] = mapped_column(String(20), nullable=False)
    akurasi: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2), nullable=True)
    format_file: Mapped[str] = mapped_column(String(10), nullable=False, default="tflite")
    deskripsi: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status_aktif: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    uploaded_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True, onupdate=datetime.utcnow
    )

    # Relationships
    uploader: Mapped[Optional["User"]] = relationship("User", foreign_keys=[uploaded_by])
    hasil_deteksi_list: Mapped[List["HasilDeteksi"]] = relationship(
        back_populates="model_cnn"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "versi": self.versi,
            "akurasi": float(self.akurasi) if self.akurasi else None,
            "format_file": self.format_file,
            "deskripsi": self.deskripsi,
            "status_aktif": self.status_aktif,
            "uploaded_by": self.uploaded_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self) -> str:
        return f"<ModelCnn id={self.id} versi={self.versi} aktif={self.status_aktif}>"
