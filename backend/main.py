"""
WP FactCheck Backend - Lightweight FastAPI Application
Integrates with Flutter frontend for real-time fact-checking with Indian context
"""
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
from dotenv import load_dotenv
import asyncio
from contextlib import asynccontextmanager

from services.perplexity_service import PerplexityService
from services.groq_service import GroqService
from services.crawler_service import CrawlerService
from services.news_service import NewsService
from services.offline_model_service import OfflineModelService
from models.fact_check_models import (
    FactCheckRequest, FactCheckResult, URLRequest, ExtractedContent
)
from models.chat_models import ChatRequest, ChatResponse
from utils.cache_manager import CacheManager
from utils.text_processor import TextProcessor

# Load environment variables
load_dotenv()

# Initialize services
cache_manager = CacheManager()
text_processor = TextProcessor()
perplexity_service = PerplexityService()
groq_service = GroqService()
crawler_service = CrawlerService()
news_service = NewsService()
offline_service = OfflineModelService()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    print("🚀 Starting WP FactCheck Backend...")
    
    # Initialize cache directories
    await cache_manager.initialize()
    
    # Load offline model
    await offline_service.load_model()
    
    print("✅ Backend ready for fact-checking!")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down WP FactCheck Backend...")

# Create FastAPI app
app = FastAPI(
    title="WP FactCheck API",
    description="Real-time fact-checking API with Indian context knowledge",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for Flutter integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/healthz")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "WP FactCheck Backend",
        "version": "1.0.0"
    }

# Fact-checking endpoints
@app.post("/api/v1/fact-check/analyze", response_model=FactCheckResult)
async def analyze_content(request: FactCheckRequest):
    """
    Analyze content for factual accuracy using Perplexity AI
    Falls back to offline model if API fails
    """
    try:
        # Validate and clean input text
        cleaned_text = text_processor.clean_text(request.text)
        
        # Check cache first
        cache_key = f"fact_check_{hash(cleaned_text)}"
        cached_result = await cache_manager.get(cache_key, "fact_checks")
        
        if cached_result:
            cached_result["is_from_cache"] = True
            return FactCheckResult(**cached_result)
        
        # Try Perplexity API first
        try:
            result = await perplexity_service.analyze_claim(
                text=cleaned_text,
                source_url=request.source_url
            )
            result["is_from_cache"] = False
            
            # Cache successful result
            await cache_manager.set(cache_key, result, "fact_checks")
            
            return FactCheckResult(**result)
            
        except Exception as perplexity_error:
            print(f"Perplexity API failed: {perplexity_error}")
            
            # Try Groq API as secondary option
            try:
                result = await groq_service.analyze_claim(
                    text=cleaned_text,
                    source_url=request.source_url
                )
                result["is_from_cache"] = False
                
                # Cache successful result
                await cache_manager.set(cache_key, result, "fact_checks")
                
                return FactCheckResult(**result)
                
            except Exception as groq_error:
                print(f"Groq API also failed: {groq_error}")
                
                # Fallback to offline model
                result = await offline_service.analyze_claim(cleaned_text)
                result["is_from_cache"] = False
                
                return FactCheckResult(**result)
            
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to analyze content",
                "error_code": "ANALYSIS_FAILED"
            }
        )

@app.post("/api/v1/fact-check/extract", response_model=ExtractedContent)
async def extract_url_content(request: URLRequest):
    """
    Extract content from news URLs for fact-checking
    Supports major Indian news websites
    """
    try:
        # Check cache first
        cache_key = f"url_extract_{hash(request.url)}"
        cached_content = await cache_manager.get(cache_key, "extracted_content")
        
        if cached_content:
            return ExtractedContent(**cached_content)
        
        # Extract content
        result = await crawler_service.extract_content(request.url)
        
        # Cache result
        await cache_manager.set(cache_key, result, "extracted_content")
        
        return ExtractedContent(**result)
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to extract URL content",
                "error_code": "EXTRACTION_FAILED"
            }
        )

# Chat endpoints
@app.post("/api/v1/chat/continue", response_model=ChatResponse)
async def continue_conversation(request: ChatRequest):
    """
    Continue conversation about fact-check results using Groq AI
    """
    try:
        # Generate response using Groq
        result = await groq_service.continue_conversation(
            fact_check_context=request.fact_check_context,
            user_message=request.user_message,
            conversation_history=request.conversation_history
        )
        
        return ChatResponse(**result)
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to generate chat response",
                "error_code": "CHAT_FAILED"
            }
        )

# News endpoints
@app.get("/api/v1/news/top-headlines")
async def get_top_headlines(
    category: str = "general",
    page: int = 1,
    pageSize: int = 20
):
    """
    Get top headlines from Indian news sources
    """
    try:
        # Check cache first
        cache_key = f"headlines_{category}_{page}_{pageSize}"
        cached_news = await cache_manager.get(cache_key, "news_feed")
        
        if cached_news:
            return cached_news
        
        # Fetch fresh news
        result = await news_service.get_top_headlines(
            category=category,
            page=page,
            page_size=pageSize
        )
        
        # Cache result
        await cache_manager.set(cache_key, result, "news_feed")
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to fetch news headlines",
                "error_code": "NEWS_FETCH_FAILED"
            }
        )

@app.get("/api/v1/news/everything")
async def search_everything(
    q: str,
    sortBy: str = "publishedAt",
    page: int = 1,
    pageSize: int = 20
):
    """
    Search news articles with query
    """
    try:
        result = await news_service.search_news(
            query=q,
            sort_by=sortBy,
            page=page,
            page_size=pageSize
        )
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to search news",
                "error_code": "NEWS_SEARCH_FAILED"
            }
        )

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle HTTP exceptions with consistent error format"""
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.detail
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions"""
    return JSONResponse(
        status_code=500,
        content={
            "status": "error",
            "message": "Internal server error",
            "error_code": "INTERNAL_ERROR"
        }
    )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", 8000)),
        reload=os.getenv("DEBUG", "False").lower() == "true"
    )
