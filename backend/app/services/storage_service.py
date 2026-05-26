import base64
import binascii
import logging
from datetime import datetime

import boto3
from botocore.config import Config as BotoConfig
from botocore.exceptions import BotoCoreError, ClientError

from app.core.config import get_settings
from app.core.exceptions import ServiceException, ValidationException

logger = logging.getLogger(__name__)
settings = get_settings()

# SigV4-signed URLs are capped at 7 days by the S3/R2 protocol. A true
# "6 month" lifetime is only possible via a public bucket domain. We store
# the object key and re-sign on demand so access can be renewed indefinitely.
_MAX_PRESIGN_TTL = 604800  # 7 days in seconds


class StorageService:
    """Cloudflare R2 (S3-compatible) object storage for medication photos."""

    def __init__(self) -> None:
        self._client = None

    @property
    def enabled(self) -> bool:
        return bool(settings.R2_ENDPOINT_URL and settings.R2_ACCESS_KEY_ID)

    @property
    def client(self):
        if self._client is None:
            self._client = boto3.client(
                "s3",
                endpoint_url=settings.R2_ENDPOINT_URL,
                aws_access_key_id=settings.R2_ACCESS_KEY_ID,
                aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
                region_name="auto",
                config=BotoConfig(signature_version="s3v4"),
            )
        return self._client

    def upload_photo(self, photo_base64: str, patient_id) -> dict:
        """Decode a base64 image and upload it to R2. Returns key + signed URL."""
        raw = self._decode(photo_base64)
        timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S%f")
        key = f"photos/{patient_id}/{timestamp}.jpg"

        if not self.enabled:
            # Dev fallback — R2 not configured. Photo is not persisted.
            logger.warning("R2 not configured; photo upload skipped for %s", key)
            return {"key": key, "url": f"local://{key}", "size": len(raw)}

        try:
            self.client.put_object(
                Bucket=settings.R2_BUCKET_NAME,
                Key=key,
                Body=raw,
                ContentType="image/jpeg",
            )
        except (BotoCoreError, ClientError) as exc:
            logger.error("R2 upload failed for %s: %s", key, exc)
            raise ServiceException(detail="Gagal mengunggah foto. Silakan coba lagi.")

        url = self.generate_presigned_url(key)
        logger.info("Photo uploaded to R2: %s (%d bytes)", key, len(raw))
        return {"key": key, "url": url, "size": len(raw)}

    def upload_bytes(
        self,
        data: bytes,
        key: str,
        content_type: str = "application/octet-stream",
    ) -> dict:
        """Upload raw bytes to R2 under an explicit key."""
        if not self.enabled:
            logger.warning("R2 not configured; upload skipped for %s", key)
            return {"key": key, "url": f"local://{key}", "size": len(data)}

        try:
            self.client.put_object(
                Bucket=settings.R2_BUCKET_NAME,
                Key=key,
                Body=data,
                ContentType=content_type,
            )
        except (BotoCoreError, ClientError) as exc:
            logger.error("R2 upload failed for %s: %s", key, exc)
            raise ServiceException(detail="Gagal mengunggah file. Silakan coba lagi.")

        url = self.generate_presigned_url(key)
        logger.info("Uploaded to R2: %s (%d bytes)", key, len(data))
        return {"key": key, "url": url, "size": len(data)}

    def generate_presigned_url(self, key: str, expires: int = _MAX_PRESIGN_TTL) -> str:
        """Generate a time-limited GET URL for an R2 object."""
        if not self.enabled:
            return f"local://{key}"
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.R2_BUCKET_NAME, "Key": key},
            ExpiresIn=min(expires, _MAX_PRESIGN_TTL),
        )

    @staticmethod
    def _decode(photo_base64: str) -> bytes:
        data = photo_base64.strip()
        # Strip data-URI prefix: "data:image/jpeg;base64,...."
        if data.startswith("data:") and "," in data:
            data = data.split(",", 1)[1]
        try:
            return base64.b64decode(data, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValidationException(detail="Data foto base64 tidak valid.") from exc


storage_service = StorageService()
