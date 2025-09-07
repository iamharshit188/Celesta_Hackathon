"""
Offline model service for fallback fact-checking when APIs are unavailable
Uses lightweight models with Indian context knowledge
"""
import os
import uuid
from typing import Dict, Any
from datetime import datetime
import re

class OfflineModelService:
    """Offline fact-checking service using rule-based analysis"""
    
    def __init__(self):
        self.model_loaded = False
        self.indian_keywords = {
            "government": ["modi", "bjp", "congress", "parliament", "lok sabha", "rajya sabha", "pib", "government"],
            "politics": ["election", "vote", "party", "minister", "pm", "chief minister", "mla", "mp"],
            "economy": ["rupee", "rbi", "reserve bank", "gst", "budget", "gdp", "inflation", "sensex", "nifty"],
            "covid": ["covid", "coronavirus", "vaccine", "lockdown", "pandemic", "omicron", "delta"],
            "bollywood": ["bollywood", "actor", "actress", "film", "movie", "cinema"],
            "cricket": ["cricket", "ipl", "bcci", "test match", "odi", "t20", "world cup"],
            "technology": ["startup", "unicorn", "tech", "ai", "digital india", "upi"]
        }
        
        # Common misinformation patterns
        self.suspicious_patterns = [
            r"breaking.*news",
            r"shocking.*truth",
            r"doctors hate this",
            r"you won't believe",
            r"secret.*revealed",
            r"urgent.*share",
            r"before.*deleted"
        ]
    
    async def load_model(self):
        """Initialize the offline model (placeholder for actual model loading)"""
        try:
            # In a real implementation, this would load a pre-trained model
            # For now, we'll use rule-based analysis
            print("📚 Loading offline Indian fact-check model...")
            
            # Simulate model loading
            self.model_loaded = True
            print("✅ Offline model ready")
            
        except Exception as e:
            print(f"⚠️  Offline model loading failed: {e}")
            self.model_loaded = False
    
    async def analyze_claim(self, text: str) -> Dict[str, Any]:
        """
        Analyze claim using offline rule-based approach
        Conservative approach - tends toward UNVERIFIED for safety
        """
        try:
            # Basic analysis using rules and patterns
            analysis_result = self._rule_based_analysis(text)
            
            return {
                "id": str(uuid.uuid4()),
                "inputText": text,
                "sourceUrl": None,
                "verdict": analysis_result["verdict"],
                "confidenceScore": analysis_result["confidence"],
                "explanation": analysis_result["explanation"],
                "sources": [],
                "keyPoints": analysis_result["key_points"],
                "analyzedAt": datetime.utcnow(),
                "isFromCache": False,
                "modelVersion": "offline-indian-v1.0"
            }
            
        except Exception as e:
            print(f"Offline analysis error: {e}")
            return self._fallback_response(text)
    
    def _rule_based_analysis(self, text: str) -> Dict[str, Any]:
        """
        Rule-based analysis for basic fact-checking
        """
        text_lower = text.lower()
        
        # Check for suspicious patterns
        suspicious_score = 0
        for pattern in self.suspicious_patterns:
            if re.search(pattern, text_lower, re.IGNORECASE):
                suspicious_score += 1
        
        # Check for Indian context
        indian_context_score = 0
        detected_categories = []
        
        for category, keywords in self.indian_keywords.items():
            category_matches = sum(1 for keyword in keywords if keyword in text_lower)
            if category_matches > 0:
                indian_context_score += category_matches
                detected_categories.append(category)
        
        # Analyze claim structure
        has_numbers = bool(re.search(r'\d+', text))
        has_dates = bool(re.search(r'\b(20\d{2}|19\d{2})\b', text))
        has_specific_claims = len(re.findall(r'\b(said|announced|reported|confirmed|denied)\b', text_lower))
        
        # Determine verdict based on analysis
        if suspicious_score >= 2:
            verdict = "MISLEADING"
            confidence = 70
            explanation = "This claim contains language patterns commonly associated with misinformation. The use of sensational phrases raises concerns about credibility."
        
        elif indian_context_score == 0 and len(text.split()) > 20:
            verdict = "UNVERIFIED"
            confidence = 40
            explanation = "This claim lacks specific Indian context and cannot be verified using our offline knowledge base. Online verification recommended."
        
        elif has_specific_claims >= 2 and (has_numbers or has_dates):
            verdict = "UNVERIFIED"
            confidence = 60
            explanation = "This claim contains specific assertions that require verification against current sources. The presence of numbers and dates suggests factual claims that need checking."
        
        else:
            verdict = "UNVERIFIED"
            confidence = 50
            explanation = "Offline analysis cannot determine the accuracy of this claim. Online fact-checking with current sources is recommended for verification."
        
        # Generate key points
        key_points = self._extract_key_points(text, detected_categories, has_numbers, has_dates)
        
        return {
            "verdict": verdict,
            "confidence": confidence,
            "explanation": explanation,
            "key_points": key_points
        }
    
    def _extract_key_points(self, text: str, categories: list, has_numbers: bool, has_dates: bool) -> list:
        """Extract key points for analysis"""
        points = []
        
        if categories:
            points.append(f"Claim relates to: {', '.join(categories)}")
        
        if has_numbers:
            numbers = re.findall(r'\b\d+(?:,\d{3})*(?:\.\d+)?\b', text)
            if numbers:
                points.append(f"Contains numerical claims: {', '.join(numbers[:3])}")
        
        if has_dates:
            dates = re.findall(r'\b(20\d{2}|19\d{2})\b', text)
            if dates:
                points.append(f"References time period: {', '.join(set(dates))}")
        
        # Extract potential entities (simple approach)
        words = text.split()
        capitalized_words = [word for word in words if word[0].isupper() and len(word) > 2]
        if capitalized_words:
            points.append(f"Key entities mentioned: {', '.join(capitalized_words[:3])}")
        
        if not points:
            points.append("General claim requiring verification")
        
        return points[:5]  # Limit to 5 points
    
    def _fallback_response(self, text: str) -> Dict[str, Any]:
        """Fallback response when analysis fails"""
        return {
            "id": str(uuid.uuid4()),
            "inputText": text,
            "sourceUrl": None,
            "verdict": "UNVERIFIED",
            "confidenceScore": 30,
            "explanation": "Offline analysis encountered an error. This claim requires manual verification using credible sources and fact-checking websites.",
            "sources": [],
            "keyPoints": ["Analysis error occurred", "Manual verification recommended"],
            "analyzedAt": datetime.utcnow(),
            "isFromCache": False,
            "modelVersion": "offline-fallback-v1.0"
        }
