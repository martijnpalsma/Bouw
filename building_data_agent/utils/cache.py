"""
Cache utilities voor data caching
"""

import json
import hashlib
from typing import Any, Optional, Callable
from datetime import datetime, timedelta
from functools import wraps

try:
    from diskcache import Cache as DiskCache
except ImportError:
    DiskCache = None

try:
    import redis
except ImportError:
    redis = None

from ..config import config
import structlog

logger = structlog.get_logger()


class Cache:
    """Cache manager voor API responses"""
    
    def __init__(self):
        self.enabled = config.cache_enabled
        self.ttl = config.cache_ttl
        self.cache_type = config.cache_type
        
        if not self.enabled:
            self._cache = None
            return
        
        if self.cache_type == "disk":
            if DiskCache is None:
                logger.warning("diskcache_not_installed", msg="Install with: pip install diskcache")
                self.enabled = False
                return
            self._cache = DiskCache('.cache/building_data')
        
        elif self.cache_type == "redis":
            if redis is None:
                logger.warning("redis_not_installed", msg="Install with: pip install redis")
                self.enabled = False
                return
            self._cache = redis.Redis(
                host=config.redis_host,
                port=config.redis_port,
                db=config.redis_db,
                password=config.redis_password,
                decode_responses=True
            )
        
        elif self.cache_type == "memory":
            self._cache = {}
        
        else:
            logger.error("invalid_cache_type", cache_type=self.cache_type)
            self.enabled = False
    
    def _generate_key(self, prefix: str, **kwargs) -> str:
        """Genereer cache key"""
        key_data = json.dumps(kwargs, sort_keys=True)
        key_hash = hashlib.md5(key_data.encode()).hexdigest()
        return f"{prefix}:{key_hash}"
    
    def get(self, key: str) -> Optional[Any]:
        """Haal waarde op uit cache"""
        if not self.enabled:
            return None
        
        try:
            if self.cache_type == "disk":
                return self._cache.get(key)
            elif self.cache_type == "redis":
                value = self._cache.get(key)
                return json.loads(value) if value else None
            elif self.cache_type == "memory":
                if key in self._cache:
                    value, expiry = self._cache[key]
                    if datetime.now() < expiry:
                        return value
                    else:
                        del self._cache[key]
                return None
        except Exception as e:
            logger.error("cache_get_error", error=str(e), key=key)
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Sla waarde op in cache"""
        if not self.enabled:
            return False
        
        ttl = ttl or self.ttl
        
        try:
            if self.cache_type == "disk":
                self._cache.set(key, value, expire=ttl)
            elif self.cache_type == "redis":
                self._cache.setex(key, ttl, json.dumps(value, default=str))
            elif self.cache_type == "memory":
                expiry = datetime.now() + timedelta(seconds=ttl)
                self._cache[key] = (value, expiry)
            return True
        except Exception as e:
            logger.error("cache_set_error", error=str(e), key=key)
            return False
    
    def delete(self, key: str) -> bool:
        """Verwijder waarde uit cache"""
        if not self.enabled:
            return False
        
        try:
            if self.cache_type == "disk":
                return self._cache.delete(key)
            elif self.cache_type == "redis":
                return bool(self._cache.delete(key))
            elif self.cache_type == "memory":
                if key in self._cache:
                    del self._cache[key]
                    return True
                return False
        except Exception as e:
            logger.error("cache_delete_error", error=str(e), key=key)
            return False
    
    def clear(self):
        """Wis alle cache"""
        if not self.enabled:
            return
        
        try:
            if self.cache_type == "disk":
                self._cache.clear()
            elif self.cache_type == "redis":
                self._cache.flushdb()
            elif self.cache_type == "memory":
                self._cache.clear()
            logger.info("cache_cleared")
        except Exception as e:
            logger.error("cache_clear_error", error=str(e))


# Globale cache instantie
cache = Cache()


def cached(prefix: str, ttl: Optional[int] = None):
    """
    Decorator voor het cachen van functie resultaten
    
    Usage:
        @cached("bag_data")
        def fetch_bag_data(postcode, huisnummer):
            ...
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Genereer cache key
            cache_key = cache._generate_key(prefix, args=args, kwargs=kwargs)
            
            # Check cache
            cached_result = cache.get(cache_key)
            if cached_result is not None:
                logger.debug("cache_hit", key=cache_key, function=func.__name__)
                return cached_result
            
            # Voer functie uit
            logger.debug("cache_miss", key=cache_key, function=func.__name__)
            result = func(*args, **kwargs)
            
            # Sla op in cache
            if result is not None:
                cache.set(cache_key, result, ttl=ttl)
            
            return result
        
        return wrapper
    return decorator
