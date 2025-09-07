import asyncio
import json
from typing import Tuple, List
import torch
import httpx
from loguru import logger

from ..utils.config import settings
from ..models.schemas import VerificationVerdict

class TextDetectionService:
    """Service for detecting fake news in text using BERT-based models or API-based alternatives."""
    
    def __init__(self):
        self.tokenizer = None
        self.model = None
        self.classifier = None
        self.is_initialized = False
        self.fallback_mode = False
        self.use_api = False
        self.client = None
        
    async def initialize(self):
        """Initialize the text detection model or API client."""
        try:
            logger.info("Initializing text detection service...")
            
            # Check if we should use API-based detection (Groq/Gemini)
            if settings.GROQ_API_KEY or settings.GEMINI_API_KEY:
                logger.info("Using API-based text detection with Groq or Gemini")
                self.use_api = True
                self.client = httpx.AsyncClient(timeout=30.0)  # Longer timeout for API calls
                self.is_initialized = True
                logger.info("API-based text detection service initialized successfully")
                return
            
            # Check PyTorch version compatibility
            if torch.__version__ < "2.1.0":
                logger.warning(f"PyTorch version {torch.__version__} detected. Using fallback mode for MVP.")
                self.fallback_mode = True
                self.is_initialized = True
                return
            
            # Load fake news detection model
            await asyncio.to_thread(self._load_model)
            
            self.is_initialized = True
            logger.info("Text detection service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize text detection service: {e}")
            # Fallback to MVP mode
            self.fallback_mode = True
            self.is_initialized = True
            logger.info("Text detection service running in fallback mode")
    
    def _load_model(self):
        """Load the model in a separate thread."""
        try:
            from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
            
            model_name = settings.FAKE_NEWS_MODEL_NAME
            
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_name,
                cache_dir=settings.MODEL_CACHE_DIR
            )
            
            self.model = AutoModelForSequenceClassification.from_pretrained(
                model_name,
                cache_dir=settings.MODEL_CACHE_DIR
            )
            
            # Create classification pipeline
            self.classifier = pipeline(
                "text-classification",
                model=self.model,
                tokenizer=self.tokenizer,
                device=0 if torch.cuda.is_available() else -1
            )
            
        except Exception as e:
            logger.error(f"Model loading failed: {e}")
            raise
    
    async def detect_fake_news(self, text: str) -> Tuple[VerificationVerdict, float, str]:
        """
        Detect if the given text contains fake news.
        
        Args:
            text: The text to analyze
            
        Returns:
            Tuple of (verdict, confidence, explanation)
        """
        if not self.is_initialized:
            raise RuntimeError("Text detection service not initialized")
        
        try:
            # Truncate text if too long
            if len(text) > settings.MAX_TEXT_LENGTH:
                text = text[:settings.MAX_TEXT_LENGTH]
                logger.warning("Text truncated due to length limit")
            
            if self.use_api:
                # Use API-based detection (Groq or Gemini)
                return await self._api_based_analysis(text)
            elif self.fallback_mode:
                # MVP fallback mode - simple heuristic analysis
                return await self._fallback_analysis(text)
            else:
                # Run classification with local model
                result = await asyncio.to_thread(self._classify_text, text)
                
                # Parse results
                verdict, confidence, explanation = self._parse_classification_result(result)
                
                logger.info(f"Text classification: {verdict} ({confidence:.2f})")
                return verdict, confidence, explanation
            
        except Exception as e:
            logger.error(f"Text detection failed: {e}")
            return VerificationVerdict.INCONCLUSIVE, 0.0, f"Analysis failed: {str(e)}"
    
    async def _fallback_analysis(self, text: str) -> Tuple[VerificationVerdict, float, str]:
        """Fallback analysis for MVP when models are not available."""
        text_lower = text.lower()
        
        # Simple heuristic analysis
        suspicious_words = [
            'fake', 'hoax', 'conspiracy', 'secret cure', 'miracle', 
            'government coverup', 'they don\'t want you to know',
            'shocking truth', 'amazing discovery', 'doctors hate this'
        ]
        
        suspicious_count = sum(1 for word in suspicious_words if word in text_lower)
        
        if suspicious_count >= 2:
            return VerificationVerdict.FAKE, 0.7, f"Text contains {suspicious_count} suspicious phrases commonly associated with misinformation."
        elif suspicious_count == 1:
            return VerificationVerdict.INCONCLUSIVE, 0.5, "Text shows some concerning patterns but requires further verification."
        else:
            return VerificationVerdict.REAL, 0.6, "Text appears to follow credible reporting patterns."
    
    def _classify_text(self, text: str):
        """Run the actual classification."""
        return self.classifier(text)
    
    def _parse_classification_result(self, result) -> Tuple[VerificationVerdict, float, str]:
        """Parse the model output into our format."""
        if not result or len(result) == 0:
            return VerificationVerdict.INCONCLUSIVE, 0.0, "No classification result"
        
        # Get the top prediction
        top_result = result[0] if isinstance(result, list) else result
        label = top_result['label'].lower()
        confidence = top_result['score']
        
        # Map model labels to our verdicts
        if 'fake' in label or 'false' in label:
            verdict = VerificationVerdict.FAKE
            explanation = f"Text classified as fake news with {confidence:.1%} confidence. The content contains characteristics commonly associated with misinformation."
        elif 'real' in label or 'true' in label:
            verdict = VerificationVerdict.REAL
            explanation = f"Text classified as legitimate with {confidence:.1%} confidence. The content appears to follow credible reporting patterns."
        else:
            verdict = VerificationVerdict.INCONCLUSIVE
            explanation = f"Classification uncertain with {confidence:.1%} confidence. The text requires additional verification."
        
        # Adjust verdict based on confidence thresholds
        if confidence < settings.LOW_CONFIDENCE_THRESHOLD:
            verdict = VerificationVerdict.INCONCLUSIVE
            explanation = f"Low confidence score ({confidence:.1%}). Verification inconclusive - manual fact-checking recommended."
        
        return verdict, confidence, explanation
    
    async def _api_based_analysis(self, text: str) -> Tuple[VerificationVerdict, float, str]:
        """Use Groq or Gemini API for fake news detection."""
        try:
            # Determine which API to use (prioritize Groq)
            if settings.GROQ_API_KEY:
                return await self._groq_analysis(text)
            elif settings.GEMINI_API_KEY:
                return await self._gemini_analysis(text)
            else:
                # Fallback if no API keys are available (shouldn't happen due to initialization check)
                logger.error("No API keys available for text detection")
                return await self._fallback_analysis(text)
        except Exception as e:
            logger.error(f"API-based analysis failed: {e}")
            return await self._fallback_analysis(text)
    
    async def _groq_analysis(self, text: str) -> Tuple[VerificationVerdict, float, str]:
        """Use Groq API for fake news detection."""
        try:
            # Groq API endpoint
            api_url = "https://api.groq.com/openai/v1/chat/completions"
            
            # Prepare the prompt for fact-checking
            system_prompt = """You are an expert fact-checker and misinformation analyst specializing in Indian news and global content.
            
            Your task is to analyze the provided text for signs of fake news, misinformation, or misleading content.
            
            Follow these steps in your analysis:
            1. Carefully examine the text for factual claims
            2. Check for sensationalist language, emotional manipulation, or propaganda techniques
            3. Identify any logical fallacies or inconsistencies
            4. Consider the credibility based on writing style and presentation
            5. For Indian news specifically, be aware of regional biases and political contexts
            
            Provide a clear verdict as one of these options:
            - REAL: The content appears factual, balanced, and from credible sources
            - FAKE: The content contains demonstrable falsehoods, fabrications, or deliberate misinformation
            - INCONCLUSIVE: There is insufficient information to make a definitive judgment
            
            Your confidence score should reflect your certainty:
            - 0.9-1.0: Very high confidence in your verdict
            - 0.7-0.89: High confidence
            - 0.5-0.69: Moderate confidence
            - 0.3-0.49: Low confidence
            - 0.0-0.29: Very low confidence
            
            Format your response STRICTLY as a JSON object with these fields:
            {"verdict": "REAL|FAKE|INCONCLUSIVE", "confidence": 0.XX, "explanation": "Your detailed explanation"}
            
            The explanation should be clear, concise, and highlight specific elements that led to your verdict.
            """
            
            user_prompt = f"Analyze this text for misinformation: '{text}'"
            
            # API request payload
            payload = {
                "model": "llama3-8b-8192",  # Using Llama 3 model via Groq
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                "temperature": 0.2,
                "max_tokens": 500
            }
            
            headers = {
                "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                "Content-Type": "application/json"
            }
            
            async with await self.client.post(api_url, json=payload, headers=headers) as response:
                if response.status_code == 200:
                    data = await response.json()
                    content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                    
                    # Parse the JSON response
                    try:
                        result = json.loads(content)
                        verdict_str = result.get("verdict", "INCONCLUSIVE")
                        confidence = float(result.get("confidence", 0.5))
                        explanation = result.get("explanation", "No explanation provided")
                        
                        # Map string verdict to enum
                        if verdict_str == "FAKE":
                            verdict = VerificationVerdict.FAKE
                        elif verdict_str == "REAL":
                            verdict = VerificationVerdict.REAL
                        else:
                            verdict = VerificationVerdict.INCONCLUSIVE
                            
                        return verdict, confidence, explanation
                    except json.JSONDecodeError:
                        # If JSON parsing fails, extract information manually
                        if "fake" in content.lower():
                            return VerificationVerdict.FAKE, 0.7, content
                        elif "real" in content.lower() or "true" in content.lower():
                            return VerificationVerdict.REAL, 0.7, content
                        else:
                            return VerificationVerdict.INCONCLUSIVE, 0.5, content
                else:
                    logger.warning(f"Groq API returned status {response.status_code}")
                    error_text = await response.text()
                    return VerificationVerdict.INCONCLUSIVE, 0.0, f"API error: {error_text}"
        
        except Exception as e:
            logger.error(f"Groq analysis failed: {e}")
            return VerificationVerdict.INCONCLUSIVE, 0.0, f"Analysis failed: {str(e)}"
    
    async def _gemini_analysis(self, text: str) -> Tuple[VerificationVerdict, float, str]:
        """Use Google Gemini API for fake news detection."""
        try:
            # Gemini API endpoint
            api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
            
            # Prepare the prompt for fact-checking
            prompt = f"""Analyze the following text for signs of fake news, misinformation, or misleading content.
            Text to analyze: '{text}'
            
            Provide your analysis in JSON format with these fields:
            {{"verdict": "REAL|FAKE|INCONCLUSIVE", "confidence": 0.XX, "explanation": "Your detailed explanation"}}
            """
            
            # API request payload
            payload = {
                "contents": [{
                    "parts": [{
                        "text": prompt
                    }]
                }],
                "generationConfig": {
                    "temperature": 0.2,
                    "maxOutputTokens": 500
                }
            }
            
            # Add API key as query parameter
            params = {"key": settings.GEMINI_API_KEY}
            
            async with await self.client.post(api_url, json=payload, params=params) as response:
                if response.status_code == 200:
                    data = await response.json()
                    content = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                    
                    # Parse the JSON response
                    try:
                        # Find JSON in the response (it might be surrounded by markdown or other text)
                        json_start = content.find('{')
                        json_end = content.rfind('}')
                        if json_start >= 0 and json_end >= 0:
                            json_str = content[json_start:json_end+1]
                            result = json.loads(json_str)
                            
                            verdict_str = result.get("verdict", "INCONCLUSIVE")
                            confidence = float(result.get("confidence", 0.5))
                            explanation = result.get("explanation", "No explanation provided")
                            
                            # Map string verdict to enum
                            if verdict_str == "FAKE":
                                verdict = VerificationVerdict.FAKE
                            elif verdict_str == "REAL":
                                verdict = VerificationVerdict.REAL
                            else:
                                verdict = VerificationVerdict.INCONCLUSIVE
                                
                            return verdict, confidence, explanation
                        else:
                            # If JSON not found, extract information manually
                            if "fake" in content.lower():
                                return VerificationVerdict.FAKE, 0.7, content
                            elif "real" in content.lower() or "true" in content.lower():
                                return VerificationVerdict.REAL, 0.7, content
                            else:
                                return VerificationVerdict.INCONCLUSIVE, 0.5, content
                    except json.JSONDecodeError:
                        # If JSON parsing fails, extract information manually
                        if "fake" in content.lower():
                            return VerificationVerdict.FAKE, 0.7, content
                        elif "real" in content.lower() or "true" in content.lower():
                            return VerificationVerdict.REAL, 0.7, content
                        else:
                            return VerificationVerdict.INCONCLUSIVE, 0.5, content
                else:
                    logger.warning(f"Gemini API returned status {response.status_code}")
                    error_text = await response.text()
                    return VerificationVerdict.INCONCLUSIVE, 0.0, f"API error: {error_text}"
        
        except Exception as e:
            logger.error(f"Gemini analysis failed: {e}")
            return VerificationVerdict.INCONCLUSIVE, 0.0, f"Analysis failed: {str(e)}"
    
    async def get_status(self) -> dict:
        """Get the current status of the text detection service."""
        if self.use_api:
            api_type = "groq" if settings.GROQ_API_KEY else "gemini" if settings.GEMINI_API_KEY else "none"
            return {
                "name": "text_detection",
                "status": "loaded" if self.is_initialized else "not_loaded",
                "mode": "api",
                "api_type": api_type,
                "model_name": "llama3-8b-8192" if api_type == "groq" else "gemini-pro" if api_type == "gemini" else "none"
            }
        else:
            return {
                "name": "text_detection",
                "status": "loaded" if self.is_initialized else "not_loaded",
                "mode": "fallback" if self.fallback_mode else "full_model",
                "model_name": settings.FAKE_NEWS_MODEL_NAME if not self.fallback_mode else "fallback_heuristics",
                "device": "cuda" if torch.cuda.is_available() else "cpu"
            }

# Create global instance
text_detection_service = TextDetectionService()
