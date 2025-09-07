"""
Groq AI service for fast chat functionality with fact-check context
Uses Groq's llama3-8b-8192 model for context-aware conversations
"""
import httpx
import json
import os
from typing import Dict, Any, List, Optional
import uuid
from datetime import datetime

class GroqService:
    """Service for Groq AI chat functionality"""
    
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        self.base_url = "https://api.groq.com/openai/v1/chat/completions"
        self.model = "llama-3.1-8b-instant"
        
        print(f"🔑 Groq API key loaded: {self.api_key[:10]}..." if self.api_key else "❌ No Groq API key found")
        
        if not self.api_key or self.api_key == "your_groq_key_here":
            print("⚠️  Groq API key not configured - chat functionality will be limited")
    
    async def continue_conversation(
        self, 
        fact_check_context: Dict[str, Any],
        user_message: str,
        conversation_history: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """
        Continue conversation about fact-check results using Groq AI
        """
        if not self.api_key or self.api_key == "your_groq_key_here":
            return self._fallback_response(user_message)
        
        # Build conversation context
        system_prompt = self._build_system_prompt(fact_check_context)
        messages = self._build_message_history(system_prompt, user_message, conversation_history)
        
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(
                    self.base_url,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": messages,
                        "max_tokens": 1000,
                        "temperature": 0.3,
                        "stream": False
                    }
                )
                
                if response.status_code != 200:
                    print(f"Groq API error: {response.status_code}")
                    return self._fallback_response(user_message)
                
                result = response.json()
                assistant_message = result["choices"][0]["message"]["content"]
                
                return {
                    "message": assistant_message,
                    "conversationId": str(uuid.uuid4()),
                    "timestamp": datetime.utcnow(),
                    "contextUsed": True
                }
                
        except Exception as e:
            print(f"Groq API request failed: {e}")
            return self._fallback_response(user_message)
    
    async def analyze_claim(self, text: str, source_url: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyze a claim using Groq AI for fact-checking
        """
        if not self.api_key or self.api_key == "your_groq_key_here":
            raise Exception("Groq API key not configured")
        
        # Build fact-checking prompt
        prompt = self._build_fact_check_prompt(text, source_url)
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    self.base_url,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {
                                "role": "system",
                                "content": "You are an expert fact-checker with deep knowledge of Indian politics, culture, history, and current events. Provide accurate analysis in the exact JSON format requested."
                            },
                            {
                                "role": "user", 
                                "content": prompt
                            }
                        ],
                        "max_tokens": 1200,
                        "temperature": 0.1,
                        "stream": False
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Groq API error: {response.status_code}")
                
                result = response.json()
                return self._parse_groq_response(result, text, source_url)
                
        except Exception as e:
            print(f"Groq API request failed: {e}")
            raise e
    
    def _build_fact_check_prompt(self, text: str, source_url: Optional[str] = None) -> str:
        """Build fact-checking prompt for Groq"""
        
        url_context = f"\n\nSource URL provided: {source_url}" if source_url else ""
        
        prompt = f"""
Analyze this claim for factual accuracy with focus on Indian context: "{text}"{url_context}

Provide response in this exact JSON format:
{{
  "verdict": "TRUE|FALSE|PARTIALLY_TRUE|MISLEADING|UNVERIFIED",
  "confidence_score": 75,
  "explanation": "Detailed analysis in 150-200 words explaining the verdict with specific evidence",
  "key_points": ["Specific factual point 1", "Specific factual point 2", "Specific factual point 3"],
  "sources": ["https://credible-source-1.com", "https://credible-source-2.com"],
  "context": "Additional relevant context about the claim"
}}

Guidelines:
- Focus on Indian context when relevant
- Be conservative with confidence scores
- Use "UNVERIFIED" for claims lacking sufficient evidence
- Provide at least 2-3 key points when possible
- Include credible sources when available
"""
        return prompt
    
    def _parse_groq_response(self, response: Dict[str, Any], original_text: str, source_url: Optional[str]) -> Dict[str, Any]:
        """Parse Groq API response into our format"""
        try:
            content = response["choices"][0]["message"]["content"]
            
            # Extract JSON from response
            json_start = content.find('{')
            json_end = content.rfind('}') + 1
            
            if json_start == -1 or json_end == 0:
                raise Exception("No JSON found in response")
            
            json_str = content[json_start:json_end]
            parsed_data = json.loads(json_str)
            
            return {
                "id": str(uuid.uuid4()),
                "inputText": original_text,
                "sourceUrl": source_url,
                "verdict": parsed_data.get("verdict", "UNVERIFIED"),
                "confidenceScore": min(parsed_data.get("confidence_score", 50), 90),  # Cap at 90%
                "explanation": parsed_data.get("explanation", "Analysis completed using Groq AI"),
                "sources": parsed_data.get("sources", [])[:5],  # Limit to 5 sources
                "keyPoints": parsed_data.get("key_points", [])[:5],  # Limit to 5 points
                "analyzedAt": datetime.utcnow(),
                "isFromCache": False,
                "modelVersion": "groq-llama3-8b"
            }
            
        except json.JSONDecodeError as e:
            print(f"Failed to parse Groq JSON response: {e}")
            # Fallback response
            return {
                "id": str(uuid.uuid4()),
                "inputText": original_text,
                "sourceUrl": source_url,
                "verdict": "UNVERIFIED",
                "confidenceScore": 40,
                "explanation": "Unable to parse detailed analysis from Groq AI. The claim requires manual verification with credible sources.",
                "sources": [],
                "keyPoints": ["Analysis parsing failed", "Manual verification recommended"],
                "analyzedAt": datetime.utcnow(),
                "isFromCache": False,
                "modelVersion": "groq-llama3-8b-fallback"
            }
        
        except Exception as e:
            print(f"Error parsing Groq response: {e}")
            raise e

    def _build_system_prompt(self, fact_check_context: Dict[str, Any]) -> str:
        """Build system prompt with fact-check context"""
        
        original_text = fact_check_context.get("inputText", "Unknown claim")
        verdict = fact_check_context.get("verdict", "UNVERIFIED")
        explanation = fact_check_context.get("explanation", "No explanation available")
        sources = fact_check_context.get("sources", [])
        key_points = fact_check_context.get("keyPoints", [])
        
        sources_text = "\n".join([f"- {source}" for source in sources[:3]]) if sources else "No sources available"
        points_text = "\n".join([f"- {point}" for point in key_points[:3]]) if key_points else "No key points available"
        
        return f"""You are a knowledgeable fact-checking assistant with expertise in Indian politics, current affairs, and media literacy. The user previously fact-checked this content:

Original Claim: "{original_text}"
Verdict: {verdict}
Explanation: {explanation}

Key Points:
{points_text}

Sources Used:
{sources_text}

Answer follow-up questions about this fact-check with complete, detailed responses. Provide:
- Current, accurate information about Indian politics and public figures
- Clear explanations of why claims are true or false
- Additional context about the political landscape
- Methodology behind fact-checking decisions
- Source credibility and verification processes

Always provide complete answers. If discussing current events, be specific about dates, positions, and recent developments. For Indian political questions, include relevant context about parties, elections, and government structure."""
    
    def _build_message_history(
        self, 
        system_prompt: str, 
        user_message: str, 
        conversation_history: Optional[List[Dict[str, Any]]] = None
    ) -> List[Dict[str, str]]:
        """Build message history for API call"""
        
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add conversation history (last 5 messages to stay within token limits)
        if conversation_history:
            for msg in conversation_history[-5:]:
                messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })
        
        # Add current user message
        messages.append({"role": "user", "content": user_message})
        
        return messages
    
    def _fallback_response(self, user_message: str) -> Dict[str, Any]:
        """Provide fallback response when Groq API is unavailable"""
        
        # Simple keyword-based responses
        message_lower = user_message.lower()
        
        if any(word in message_lower for word in ["source", "sources"]):
            response = "I'd be happy to help you understand the sources used in the fact-check. The sources are evaluated based on their credibility, expertise, and track record. For Indian content, we prioritize government sources, established media outlets, and verified fact-checking organizations."
        
        elif any(word in message_lower for word in ["how", "method", "process"]):
            response = "Our fact-checking process involves multiple steps: analyzing the claim's key assertions, cross-referencing with credible sources, evaluating evidence quality, and determining confidence levels. We use both AI analysis and established fact-checking methodologies."
        
        elif any(word in message_lower for word in ["confidence", "sure", "certain"]):
            response = "Confidence scores reflect the strength of available evidence. Higher scores indicate stronger supporting evidence from multiple credible sources. Lower scores suggest limited evidence or conflicting information requiring further verification."
        
        elif any(word in message_lower for word in ["indian", "india", "context"]):
            response = "For Indian context, we consider cultural, political, and historical factors that might affect claim interpretation. We prioritize Indian government sources, established Indian media, and local fact-checking organizations for the most relevant analysis."
        
        else:
            response = "I'm here to help you understand the fact-check results. You can ask me about the sources used, the methodology, confidence levels, or request additional context about the claim. What specific aspect would you like to know more about?"
        
        return {
            "message": response,
            "conversationId": str(uuid.uuid4()),
            "timestamp": datetime.utcnow(),
            "contextUsed": False
        }
