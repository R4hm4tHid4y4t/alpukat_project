import random
import string
from passlib.context import CryptContext

# Konfigurasi context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

def hash_password(plain: str) -> str:
    """
    Melakukan hashing password dengan bcrypt.
    Membatasi panjang password hingga 72 karakter karena limitasi bcrypt.
    """
    # Batasi password maksimal 72 karakter agar tidak terjadi error ValueError
    if len(plain) > 72:
        plain = plain[:72]
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    """
    Verifikasi password. Jika password yang diberikan > 72 karakter,
    kita potong terlebih dahulu agar cocok dengan hash yang disimpan.
    """
    if len(plain) > 72:
        plain = plain[:72]
    return pwd_context.verify(plain, hashed)


def generate_otp(length: int = 6) -> str:
    """Menghasilkan OTP acak."""
    return "".join(random.choices(string.digits, k=length))