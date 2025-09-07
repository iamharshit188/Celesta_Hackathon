import asyncio
import tempfile
import os
import uuid
from datetime import datetime
from typing import List
from fastapi import APIRouter, HTTPException, UploadFile, File, Depends
from loguru import logger

from ..models.schemas import (
    TextVerificationRequest,
    URLVerificationRequest,
    VoiceVerificationRequest,
    VerificationResult,
    InputMethod,
    FactCheckSource
)
from ..services.text_detection import text_detection_service
from ..services.speech_to_text import speech_to_text_service
from ..services.web_crawler import web_crawler_service
from ..services.deepfake_detection import deepfake_detection_service
from ..utils.config import settings

router = APIRouter()

@router.post("/text", response_model=VerificationResult)
async def verify_text(request: TextVerificationRequest):
    """Verify text content for fake news."""
    try:
        logger.info(f"Text verification request: {len(request.text)} characters")
        
        # Detect fake news in text using Groq API
        verdict, confidence, explanation = await text_detection_service.detect_fake_news(request.text)
        
        # Search for fact-check sources
        sources = await web_crawler_service.search_fact_check_sources(request.text[:200])
        
        # Enhance explanation with clear verdict statement
        verdict_statement = ""
        if verdict.value == "FAKE":
            verdict_statement = "⚠️ VERDICT: This content appears to be FAKE NEWS. ⚠️\n\n"
        elif verdict.value == "REAL":
            verdict_statement = "✅ VERDICT: This content appears to be REAL NEWS. ✅\n\n"
        else:
            verdict_statement = "⚠️ VERDICT: The authenticity of this content is INCONCLUSIVE. Further verification needed. ⚠️\n\n"
        
        enhanced_explanation = f"{verdict_statement}{explanation}"
        
        result = VerificationResult(
            id=str(uuid.uuid4()),
            input_text=request.text,
            input_method=InputMethod.TEXT,
            verdict=verdict,
            confidence=confidence,
            explanation=enhanced_explanation,
            sources=sources,
            timestamp=datetime.utcnow(),
            additional_data={
                "text_length": len(request.text),
                "processing_time_ms": 0,  # Would be calculated in production
                "analysis_method": "Groq API (Llama 3)"
            }
        )
        
        logger.info(f"Text verification completed: {verdict} ({confidence:.2f})")
        return result
        
    except Exception as e:
        logger.error(f"Text verification failed: {e}")
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@router.post("/voice", response_model=VerificationResult)
async def verify_voice(request: VoiceVerificationRequest):
    """Verify voice content by transcribing and analyzing text."""
    try:
        logger.info("Voice verification request received")
        
        # Transcribe audio to text using Groq API (Whisper model)
        transcript = await speech_to_text_service.transcribe_audio(
            request.audio_data,
            request.format,
            request.sample_rate
        )
        
        if not transcript or transcript.strip() == "":
            raise HTTPException(status_code=400, detail="No speech detected in audio")
        
        # Analyze transcribed text using Groq API
        verdict, confidence, explanation = await text_detection_service.detect_fake_news(transcript)
        
        # Search for fact-check sources based on transcript
        sources = await web_crawler_service.search_fact_check_sources(transcript[:200])
        
        # Enhance explanation with clear verdict statement
        verdict_statement = ""
        if verdict.value == "FAKE":
            verdict_statement = "⚠️ VERDICT: This content appears to be FAKE NEWS. ⚠️\n\n"
        elif verdict.value == "REAL":
            verdict_statement = "✅ VERDICT: This content appears to be REAL NEWS. ✅\n\n"
        else:
            verdict_statement = "⚠️ VERDICT: The authenticity of this content is INCONCLUSIVE. Further verification needed. ⚠️\n\n"
        
        # Format the transcript and explanation
        formatted_transcript = f"Transcription: '{transcript[:100]}{'...' if len(transcript) > 100 else ''}'"
        enhanced_explanation = f"{verdict_statement}{formatted_transcript}\n\n{explanation}"
        
        result = VerificationResult(
            id=str(uuid.uuid4()),
            input_text=transcript,
            input_method=InputMethod.VOICE,
            verdict=verdict,
            confidence=confidence,
            explanation=enhanced_explanation,
            sources=sources,
            timestamp=datetime.utcnow(),
            additional_data={
                "transcript": transcript,
                "audio_format": request.format,
                "sample_rate": request.sample_rate,
                "transcription_method": "Groq API (Whisper model)",
                "analysis_method": "Groq API (Llama 3)"
            }
        )
        
        logger.info(f"Voice verification completed: {verdict} ({confidence:.2f})")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Voice verification failed: {e}")
        raise HTTPException(status_code=500, detail=f"Voice verification failed: {str(e)}")

@router.post("/url", response_model=VerificationResult)
async def verify_url(request: URLVerificationRequest):
    """Verify content from a URL."""
    try:
        logger.info(f"URL verification request: {request.url}")
        
        # Extract content from URL
        title, content, metadata = await web_crawler_service.extract_article_content(request.url)
        
        if not content:
            raise HTTPException(status_code=400, detail="Could not extract content from URL")
        
        # Combine title and content for analysis
        full_text = f"{title}\n\n{content}"
        
        # Analyze extracted content
        verdict, confidence, explanation = await text_detection_service.detect_fake_news(full_text)
        
        # Search for fact-check sources
        search_query = title if title else content[:200]
        sources = await web_crawler_service.search_fact_check_sources(search_query)
        
        result = VerificationResult(
            id=str(uuid.uuid4()),
            input_text=full_text[:1000],  # Truncate for storage
            input_method=InputMethod.URL,
            verdict=verdict,
            confidence=confidence,
            explanation=explanation,
            sources=sources,
            timestamp=datetime.utcnow(),
            additional_data={
                "source_url": request.url,
                "title": title,
                "content_length": len(content),
                "metadata": metadata
            }
        )
        
        logger.info(f"URL verification completed: {verdict} ({confidence:.2f})")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"URL verification failed: {e}")
        raise HTTPException(status_code=500, detail=f"URL verification failed: {str(e)}")

@router.post("/video", response_model=VerificationResult)
async def verify_video(file: UploadFile = File(...)):
    """Verify video content for deepfakes."""
    try:
        logger.info(f"Video verification request: {file.filename}")
        
        # Validate file
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file provided")
        
        file_ext = os.path.splitext(file.filename)[1].lower()
        if file_ext not in settings.ALLOWED_VIDEO_FORMATS_LIST:
            raise HTTPException(
                status_code=400, 
                detail=f"Unsupported file format. Allowed: {settings.ALLOWED_VIDEO_FORMATS_LIST}"
            )
        
        # Check file size
        contents = await file.read()
        if len(contents) > settings.MAX_FILE_SIZE:
            raise HTTPException(status_code=400, detail="File too large")
        
        # Save temporary file
        with tempfile.NamedTemporaryFile(suffix=file_ext, delete=False) as temp_file:
            temp_file.write(contents)
            temp_file_path = temp_file.name
        
        try:
            # Analyze video for deepfakes
            verdict, confidence, explanation = await deepfake_detection_service.detect_deepfake(temp_file_path)
            
            # For video analysis, we might not have traditional fact-check sources
            # but we could add technical analysis sources in the future
            sources = []
            
            result = VerificationResult(
                id=str(uuid.uuid4()),
                input_text=f"Video analysis: {file.filename}",
                input_method=InputMethod.VIDEO,
                verdict=verdict,
                confidence=confidence,
                explanation=explanation,
                sources=sources,
                timestamp=datetime.utcnow(),
                additional_data={
                    "filename": file.filename,
                    "file_size": len(contents),
                    "file_format": file_ext
                }
            )
            
            logger.info(f"Video verification completed: {verdict} ({confidence:.2f})")
            return result
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Video verification failed: {e}")
        raise HTTPException(status_code=500, detail=f"Video verification failed: {str(e)}")
