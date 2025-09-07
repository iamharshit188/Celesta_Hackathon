import asyncio
from typing import List, Dict
from datetime import datetime
from loguru import logger

from .text_detection import text_detection_service
from .speech_to_text import speech_to_text_service
from .web_crawler import web_crawler_service
from .deepfake_detection import deepfake_detection_service
from ..models.schemas import ModelStatus

class ModelManager:
    """Central manager for all AI models and services."""
    
    services = [
        text_detection_service,
        speech_to_text_service,
        web_crawler_service,
        deepfake_detection_service,
    ]
    
    @classmethod
    async def initialize(cls):
        """Initialize all services concurrently."""
        logger.info("Initializing all AI services...")
        
        # Initialize all services concurrently
        initialization_tasks = []
        for service in cls.services:
            task = asyncio.create_task(service.initialize())
            initialization_tasks.append(task)
        
        # Wait for all services to initialize
        results = await asyncio.gather(*initialization_tasks, return_exceptions=True)
        
        # Check results
        failed_services = []
        for i, result in enumerate(results):
            service_name = cls.services[i].__class__.__name__
            if isinstance(result, Exception):
                logger.error(f"Failed to initialize {service_name}: {result}")
                failed_services.append(service_name)
            else:
                logger.info(f"Successfully initialized {service_name}")
        
        if failed_services:
            logger.warning(f"Some services failed to initialize: {failed_services}")
        else:
            logger.info("All AI services initialized successfully")
    
    @classmethod
    async def get_status(cls) -> List[ModelStatus]:
        """Get status of all services."""
        status_tasks = []
        
        for service in cls.services:
            if hasattr(service, 'get_status'):
                task = asyncio.create_task(service.get_status())
                status_tasks.append(task)
        
        status_results = await asyncio.gather(*status_tasks, return_exceptions=True)
        
        model_statuses = []
        for i, result in enumerate(status_results):
            if isinstance(result, Exception):
                model_status = ModelStatus(
                    name=cls.services[i].__class__.__name__,
                    status="error",
                    error_message=str(result)
                )
            else:
                model_status = ModelStatus(
                    name=result.get('name', 'unknown'),
                    status=result.get('status', 'unknown'),
                    last_used=datetime.now() if result.get('status') == 'loaded' else None
                )
            model_statuses.append(model_status)
        
        return model_statuses
    
    @classmethod
    async def cleanup(cls):
        """Cleanup all services."""
        logger.info("Cleaning up AI services...")
        
        cleanup_tasks = []
        for service in cls.services:
            if hasattr(service, 'cleanup'):
                task = asyncio.create_task(service.cleanup())
                cleanup_tasks.append(task)
        
        if cleanup_tasks:
            await asyncio.gather(*cleanup_tasks, return_exceptions=True)
        
        logger.info("AI services cleanup completed")
