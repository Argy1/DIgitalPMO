import redis as _redis

from app.core.config import get_settings

_settings = get_settings()

redis_client: _redis.Redis = _redis.from_url(
    _settings.REDIS_URL,
    decode_responses=True,
)
