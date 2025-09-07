"""
Simple file-based cache manager for storing analysis results
No database required - uses JSON files for persistence
"""
import json
import os
import aiofiles
from datetime import datetime, timedelta
from typing import Any, Optional, Dict
import hashlib

class CacheManager:
    """File-based cache manager with TTL support"""
    
    def __init__(self, cache_dir: str = "./data/cache"):
        self.cache_dir = cache_dir
        self.cache_types = {
            "fact_checks": int(os.getenv("FACT_CHECK_CACHE_TTL", 86400)),  # 24 hours
            "news_feed": int(os.getenv("NEWS_CACHE_TTL", 3600)),          # 1 hour
            "conversations": int(os.getenv("CHAT_CACHE_TTL", 604800)),    # 7 days
            "extracted_content": int(os.getenv("URL_CACHE_TTL", 21600))   # 6 hours
        }
    
    async def initialize(self):
        """Initialize cache directories"""
        for cache_type in self.cache_types.keys():
            cache_path = os.path.join(self.cache_dir, cache_type)
            os.makedirs(cache_path, exist_ok=True)
    
    def _get_cache_path(self, key: str, cache_type: str) -> str:
        """Get file path for cache key"""
        safe_key = hashlib.md5(key.encode()).hexdigest()
        return os.path.join(self.cache_dir, cache_type, f"{safe_key}.json")
    
    async def get(self, key: str, cache_type: str) -> Optional[Dict[str, Any]]:
        """Get cached data if not expired"""
        try:
            cache_path = self._get_cache_path(key, cache_type)
            
            if not os.path.exists(cache_path):
                return None
            
            async with aiofiles.open(cache_path, 'r') as f:
                content = await f.read()
                data = json.loads(content)
            
            # Check expiry
            cached_time = datetime.fromisoformat(data['cached_at'])
            ttl = self.cache_types.get(cache_type, 3600)
            
            if datetime.utcnow() - cached_time > timedelta(seconds=ttl):
                # Expired, remove file
                os.remove(cache_path)
                return None
            
            return data['content']
            
        except Exception as e:
            print(f"Cache get error: {e}")
            return None
    
    async def set(self, key: str, value: Dict[str, Any], cache_type: str):
        """Set cached data with timestamp"""
        try:
            cache_path = self._get_cache_path(key, cache_type)
            
            cache_data = {
                'content': value,
                'cached_at': datetime.utcnow().isoformat(),
                'cache_type': cache_type
            }
            
            async with aiofiles.open(cache_path, 'w') as f:
                await f.write(json.dumps(cache_data, indent=2))
                
        except Exception as e:
            print(f"Cache set error: {e}")
    
    async def delete(self, key: str, cache_type: str):
        """Delete cached data"""
        try:
            cache_path = self._get_cache_path(key, cache_type)
            if os.path.exists(cache_path):
                os.remove(cache_path)
        except Exception as e:
            print(f"Cache delete error: {e}")
    
    async def clear_expired(self):
        """Clear all expired cache entries"""
        try:
            for cache_type in self.cache_types.keys():
                cache_dir = os.path.join(self.cache_dir, cache_type)
                if not os.path.exists(cache_dir):
                    continue
                
                for filename in os.listdir(cache_dir):
                    if filename.endswith('.json'):
                        filepath = os.path.join(cache_dir, filename)
                        try:
                            with open(filepath, 'r') as f:
                                data = json.load(f)
                            
                            cached_time = datetime.fromisoformat(data['cached_at'])
                            ttl = self.cache_types.get(cache_type, 3600)
                            
                            if datetime.utcnow() - cached_time > timedelta(seconds=ttl):
                                os.remove(filepath)
                                
                        except Exception:
                            # Remove corrupted cache files
                            os.remove(filepath)
                            
        except Exception as e:
            print(f"Cache cleanup error: {e}")
