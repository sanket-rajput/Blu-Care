import logging
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import get_optional_user
from app.core.database import get_db
from app.db.models import UserProfileModel, UserSettingsModel
from app.schemas.api import (
    UserProfile,
    UserProfileUpdate,
    UserSettings,
    UserSettingsUpdate,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user", tags=["User Profile & Settings"])

# In-memory storage fallback
_USER_PROFILES: Dict[str, UserProfile] = {}
_USER_SETTINGS: Dict[str, UserSettings] = {}


@router.get("/profile", response_model=UserProfile)
async def get_profile(
    user_id: str = Depends(get_optional_user),
    db: Optional[Session] = Depends(get_db),
):
    """Fetches demographics, allergies, and emergency contacts for current user."""
    if db:
        try:
            db_profile = db.query(UserProfileModel).filter(UserProfileModel.user_id == user_id).first()
            if db_profile:
                return UserProfile(
                    user_id=db_profile.user_id,
                    name=db_profile.name or "Patient",
                    email=db_profile.email or "patient@blucare.ai",
                    age=db_profile.age or 32,
                    gender=db_profile.gender or "Unspecified",
                    bloodGroup=db_profile.blood_group or "O+",
                    knownAllergies=db_profile.known_allergies or [],
                    emergencyContact=db_profile.emergency_contact or "+1 (555) 019-2834",
                    medicalHistory=db_profile.medical_history or [],
                )
        except Exception as e:
            logger.warning(f"Database fetch failed for profile {user_id}: {e}")

    if user_id not in _USER_PROFILES:
        _USER_PROFILES[user_id] = UserProfile(user_id=user_id)
    return _USER_PROFILES[user_id]


@router.put("/profile", response_model=UserProfile)
async def update_profile(
    updates: UserProfileUpdate,
    user_id: str = Depends(get_optional_user),
    db: Optional[Session] = Depends(get_db),
):
    """Updates demographics, allergies, or emergency contacts for current user."""
    profile = await get_profile(user_id, db)
    updated_data = profile.model_dump()

    for field, val in updates.model_dump(exclude_unset=True).items():
        if val is not None:
            updated_data[field] = val

    updated_profile = UserProfile(**updated_data)

    if db:
        try:
            db_profile = db.query(UserProfileModel).filter(UserProfileModel.user_id == user_id).first()
            if not db_profile:
                db_profile = UserProfileModel(user_id=user_id)
                db.add(db_profile)

            db_profile.name = updated_profile.name
            db_profile.email = updated_profile.email
            db_profile.age = updated_profile.age
            db_profile.gender = updated_profile.gender
            db_profile.blood_group = updated_profile.bloodGroup
            db_profile.known_allergies = updated_profile.knownAllergies
            db_profile.emergency_contact = updated_profile.emergencyContact
            db_profile.medical_history = updated_profile.medicalHistory
            db.commit()
            db.refresh(db_profile)
        except Exception as e:
            logger.warning(f"Database update failed for profile {user_id}: {e}")
            db.rollback()

    _USER_PROFILES[user_id] = updated_profile
    return _USER_PROFILES[user_id]


@router.get("/settings", response_model=UserSettings)
async def get_settings(
    user_id: str = Depends(get_optional_user),
    db: Optional[Session] = Depends(get_db),
):
    """Fetches clinical care protocol and sensitivity preferences for current user."""
    if db:
        try:
            db_settings = db.query(UserSettingsModel).filter(UserSettingsModel.user_id == user_id).first()
            if db_settings:
                return UserSettings(
                    user_id=db_settings.user_id,
                    selectedProtocol=db_settings.selected_protocol or "WHO Triage Standard 2026",
                    sensitivityLevel=db_settings.sensitivity_level or "Balanced",
                    enableAyurvedic=db_settings.enable_ayurvedic.lower() == "true" if db_settings.enable_ayurvedic else True,
                    enableTelehealth=db_settings.enable_telehealth.lower() == "true" if db_settings.enable_telehealth else True,
                    language=db_settings.language or "English",
                    theme=db_settings.theme or "dark",
                )
        except Exception as e:
            logger.warning(f"Database fetch failed for settings {user_id}: {e}")

    if user_id not in _USER_SETTINGS:
        _USER_SETTINGS[user_id] = UserSettings(user_id=user_id)
    return _USER_SETTINGS[user_id]


@router.put("/settings", response_model=UserSettings)
async def update_settings(
    updates: UserSettingsUpdate,
    user_id: str = Depends(get_optional_user),
    db: Optional[Session] = Depends(get_db),
):
    """Updates care protocol standard or symptom matching sensitivity for current user."""
    settings_obj = await get_settings(user_id, db)
    updated_data = settings_obj.model_dump()

    for field, val in updates.model_dump(exclude_unset=True).items():
        if val is not None:
            updated_data[field] = val

    updated_settings = UserSettings(**updated_data)

    if db:
        try:
            db_settings = db.query(UserSettingsModel).filter(UserSettingsModel.user_id == user_id).first()
            if not db_settings:
                db_settings = UserSettingsModel(user_id=user_id)
                db.add(db_settings)

            db_settings.selected_protocol = updated_settings.selectedProtocol
            db_settings.sensitivity_level = updated_settings.sensitivityLevel
            db_settings.enable_ayurvedic = str(updated_settings.enableAyurvedic).lower()
            db_settings.enable_telehealth = str(updated_settings.enableTelehealth).lower()
            db_settings.language = updated_settings.language
            db_settings.theme = updated_settings.theme
            db.commit()
            db.refresh(db_settings)
        except Exception as e:
            logger.warning(f"Database update failed for settings {user_id}: {e}")
            db.rollback()

    _USER_SETTINGS[user_id] = updated_settings
    return _USER_SETTINGS[user_id]

