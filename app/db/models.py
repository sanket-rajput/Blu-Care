import time
from sqlalchemy import Column, String, Float, JSON, Integer, Text
from app.core.database import Base


class UserProfileModel(Base):
    __tablename__ = "user_profiles"

    user_id = Column(String(128), primary_key=True, index=True)
    name = Column(String(256), nullable=True)
    email = Column(String(256), nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(String(64), nullable=True)
    blood_group = Column(String(16), nullable=True)
    known_allergies = Column(JSON, default=list)
    emergency_contact = Column(String(128), nullable=True)
    medical_history = Column(JSON, default=list)
    updated_at = Column(Float, default=time.time, onupdate=time.time)


class UserSettingsModel(Base):
    __tablename__ = "user_settings"

    user_id = Column(String(128), primary_key=True, index=True)
    selected_protocol = Column(String(128), default="WHO Triage Standard 2026")
    sensitivity_level = Column(String(64), default="Balanced")
    enable_ayurvedic = Column(String(16), default="true")
    enable_telehealth = Column(String(16), default="true")
    language = Column(String(32), default="English")
    theme = Column(String(32), default="dark")
    updated_at = Column(Float, default=time.time, onupdate=time.time)


class SessionMetadataModel(Base):
    __tablename__ = "session_metadata"

    thread_id = Column(String(128), primary_key=True, index=True)
    session_id = Column(String(128), index=True)
    user_id = Column(String(128), index=True)
    title = Column(Text, nullable=True)
    message_count = Column(Integer, default=0)
    created_at = Column(Float, default=time.time)
    updated_at = Column(Float, default=time.time, onupdate=time.time)
