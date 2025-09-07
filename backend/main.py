from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import uvicorn
from loguru import logger

from app.api import verification, news
from app.services.model_manager import ModelManager
from app.utils.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and cleanup application resources."""
    logger.info("Starting Fake News Detector API")
    
    # Initialize ML models
    try:
        await ModelManager.initialize()
        logger.info("All models initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize models: {e}")
        raise
    
    yield
    
    # Cleanup
    logger.info("Shutting down Fake News Detector API")

app = FastAPI(
    title="Fake News & Deepfake Detection API",
    description="Multi-modal API for detecting fake news and deepfakes using open-source models",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(verification.router, prefix="/api/v1/verify", tags=["verification"])
app.include_router(news.router, prefix="/api/v1/news", tags=["news"])

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "message": "Fake News & Deepfake Detection API",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Detailed health check with model status."""
    try:
        model_status = await ModelManager.get_status()
        return {
            "status": "healthy",
            "models": model_status,
            "timestamp": "2024-01-01T00:00:00Z"
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Service unavailable")

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )
