from datetime import datetime
from typing import Optional
from sqlalchemy import String, Text, DateTime, ForeignKey, Integer, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class HasilDeteksi(Base):
    __tablename__ = "hasil_deteksi"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    model_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("model_cnn.id", ondelete="SET NULL"), nullable=True
    )
    varietas_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("varietas.id", ondelete="SET NULL"), nullable=True
    )
    kematangan_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("tingkat_kematangan.id", ondelete="SET NULL"), nullable=True
    )
    gambar_input: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    confidence_varietas: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2), nullable=True)
    confidence_kematangan: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2), nullable=True)
    status_flag: Mapped[str] = mapped_column(String(20), nullable=False, default="normal")
    catatan_flag: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False, index=True
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="hasil_deteksi_list")
    model_cnn: Mapped[Optional["ModelCnn"]] = relationship(back_populates="hasil_deteksi_list")
    varietas: Mapped[Optional["Varietas"]] = relationship(back_populates="hasil_deteksi_list")
    kematangan: Mapped[Optional["TingkatKematangan"]] = relationship(
        back_populates="hasil_deteksi_list"
    )
    riwayat_list: Mapped[list["RiwayatDeteksi"]] = relationship(
        back_populates="hasil", cascade="all, delete-orphan"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "model_id": self.model_id,
            "varietas_id": self.varietas_id,
            "kematangan_id": self.kematangan_id,
            "gambar_input": self.gambar_input,
            "confidence_varietas": float(self.confidence_varietas) if self.confidence_varietas else None,
            "confidence_kematangan": float(self.confidence_kematangan) if self.confidence_kematangan else None,
            "status_flag": self.status_flag,
            "catatan_flag": self.catatan_flag,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self) -> str:
        return f"<HasilDeteksi id={self.id} user_id={self.user_id} flag={self.status_flag}>"


class RiwayatDeteksi(Base):
    __tablename__ = "riwayat_deteksi"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    hasil_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hasil_deteksi.id", ondelete="CASCADE"), nullable=False
    )
    aksi: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="riwayat_list")
    hasil: Mapped["HasilDeteksi"] = relationship(back_populates="riwayat_list")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "hasil_id": self.hasil_id,
            "aksi": self.aksi,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self) -> str:
        return f"<RiwayatDeteksi id={self.id} aksi={self.aksi}>"
