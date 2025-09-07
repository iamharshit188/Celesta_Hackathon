from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class VerificationVerdict(str, Enum):
    REAL = "real"
    FAKE = "fake"
    INCONCLUSIVE = "inconclusive"

class InputMethod(str, Enum):
    TEXT = "text"
    VOICE = "voice"
    URL = "url"
    VIDEO = "video"

# Request Models
class TextVerificationRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000)
    
    @validator('text')
    def validate_text(cls, v):
        if not v.strip():
            raise ValueError('Text cannot be empty')
        return v.strip()

class URLVerificationRequest(BaseModel):
    url: str = Field(..., pattern=r'^https?://.+')
    
    @validator('url')
    def validate_url(cls, v):
        if not v.startswith(('http://', 'https://')):
            raise ValueError('URL must start with http:// or https://')
        return v

class VoiceVerificationRequest(BaseModel):
    audio_data: str  # Base64 encoded audio
    format: str = Field(default="wav")
    sample_rate: int = Field(default=16000)

# Response Models
class FactCheckSource(BaseModel):
    title: str
    url: str
    summary: str
    reliability: float = Field(..., ge=0.0, le=1.0)
    domain: str

class VerificationResult(BaseModel):
    id: str
    input_text: str
    input_method: InputMethod
    verdict: VerificationVerdict
    confidence: float = Field(..., ge=0.0, le=1.0)
    explanation: str
    sources: List[FactCheckSource] = []
    timestamp: datetime
    additional_data: Optional[Dict[str, Any]] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class NewsArticle(BaseModel):
    id: str
    title: str
    summary: str
    source: str
    image_url: str = ""
    url: str
    published_at: datetime
    category: str = "General"
    credibility_score: float = Field(..., ge=0.0, le=1.0)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class NewsFeedResponse(BaseModel):
    articles: List[NewsArticle]
    total_count: int
    category: str
    has_more: bool = False

class SearchNewsRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=200)
    limit: int = Field(default=20, ge=1, le=100)
    category: Optional[str] = None

class SearchNewsResponse(BaseModel):
    articles: List[NewsArticle]
    query: str
    total_count: int
    took_ms: int

# Error Models
class ErrorDetail(BaseModel):
    message: str
    code: str
    details: Optional[Dict[str, Any]] = None

class ErrorResponse(BaseModel):
    error: ErrorDetail
    timestamp: datetime
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

# Health Check Models
class ModelStatus(BaseModel):
    name: str
    status: str  # "loaded", "loading", "error"
    last_used: Optional[datetime] = None
    error_message: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    models: List[ModelStatus]
    timestamp: datetime
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
