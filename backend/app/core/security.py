import hashlib
import bcrypt
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from app.core.config import settings

# bcrypt wheel / passlib compatibility is brittle on some local setups.
# argon2-cffi is already installed and is a better default for new hashes.
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

ALGORITHM = "HS256"

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES if hasattr(settings, 'ACCESS_TOKEN_EXPIRE_MINUTES') else 1440)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_password(plain_password, hashed_password):
    password_sha256 = hashlib.sha256(plain_password.encode()).hexdigest().encode()
    return bcrypt.checkpw(password_sha256, hashed_password.encode() if isinstance(hashed_password, str) else hashed_password)

def get_password_hash(password):
    password_sha256 = hashlib.sha256(password.encode()).hexdigest().encode()
    return bcrypt.hashpw(password_sha256, bcrypt.gensalt()).decode()

def decode_token(token: str):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None
