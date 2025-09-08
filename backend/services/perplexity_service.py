"""
Perplexity AI service for real-time fact-checking with Indian context
Uses Perplexity's sonar-pro model for comprehensive analysis
"""
import httpx
import json
import os
from typing import Dict, Any, Optional
import uuid
from datetime import datetime

class PerplexityService:
    """Service for Perplexity AI fact-checking"""
    
    def __init__(self):
        self.api_key = os.getenv("PERPLEXITY_API_KEY")
        self.base_url = "https://api.perplexity.ai/chat/completions"
        self.model = "sonar-pro"
        
        print(f"🔑 Perplexity API key loaded: {self.api_key[:10]}..." if self.api_key else "❌ No Perplexity API key found")
        
        if not self.api_key or self.api_key == "your_perplexity_key_here":
            print("⚠️  Perplexity API key not configured - will use offline fallback")
    
    async def analyze_claim(self, text: str, source_url: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyze a claim using Perplexity AI with Indian context focus
        """
        if not self.api_key or self.api_key == "your_perplexity_key_here":
            raise Exception("Perplexity API key not configured")
        
        # Construct prompt with Indian context emphasis
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
                                "content": "You are an expert fact-checker with deep knowledge of Indian politics, culture, history, and current events. Provide accurate, well-researched analysis with credible sources."
                            },
                            {
                                "role": "user", 
                                "content": prompt
                            }
                        ],
                        "max_tokens": 1000,
                        "temperature": 0.1,
                        "return_citations": True,
                        "search_domain_filter": ["in"]
                    }
                )
                
                if response.status_code != 200:
                    error_text = response.text if hasattr(response, 'text') else str(response.content)
                    print(f"Perplexity API error {response.status_code}: {error_text}")
                    raise Exception(f"Perplexity API error: {response.status_code} - {error_text}")
                
                result = response.json()
                return self._parse_perplexity_response(result, text, source_url)
                
        except Exception as e:
            print(f"Perplexity API request failed: {e}")
            raise e
    
    def _build_fact_check_prompt(self, text: str, source_url: Optional[str] = None) -> str:
        """Build comprehensive fact-checking prompt"""
        
        url_context = f"\n\nSource URL provided: {source_url}" if source_url else ""
        
        prompt = f"""
Analyze this claim for factual accuracy with focus on Indian context: "{text}"{url_context}

Provide response in this exact JSON format:
{{
  "verdict": "TRUE|FALSE|PARTIALLY_TRUE|MISLEADING|UNVERIFIED",
  "confidence_score": 85,
  "explanation": "Detailed analysis in 150-200 words explaining the verdict with specific evidence",
  "key_points": ["Specific factual point 1", "Specific factual point 2", "Specific factual point 3"],
  "sources": ["https://credible-source-1.com", "https://credible-source-2.com"],
  "context": "Additional relevant context about the claim, especially Indian political/cultural context if applicable"
}}

Guidelines:
- Prioritize Indian government sources, established Indian media, and verified Indian fact-checkers
- Consider Indian cultural, political, and historical context
- Be conservative with confidence scores for complex claims
- Use "UNVERIFIED" for claims lacking sufficient evidence
- Include at least 2-3 credible sources when possible
- Focus on recent developments if the claim is time-sensitive
"""
        return prompt
    
    def _parse_perplexity_response(self, response: Dict[str, Any], original_text: str, source_url: Optional[str]) -> Dict[str, Any]:
        """Parse Perplexity API response into our format"""
        try:
            content = response["choices"][0]["message"]["content"]
            
            # Extract JSON from response
            json_start = content.find('{')
            json_end = content.rfind('}') + 1
            
            if json_start == -1 or json_end == 0:
                raise Exception("No JSON found in response")
            
            json_str = content[json_start:json_end]
            parsed_data = json.loads(json_str)
            
            # Extract citations if available
            citations = []
            if "citations" in response:
                citations = [cite.get("url", "") for cite in response["citations"]]
            
            # Merge sources from parsed response and citations
            all_sources = list(set(parsed_data.get("sources", []) + citations))
            
            return {
                "id": str(uuid.uuid4()),
                "inputText": original_text,
                "sourceUrl": source_url,
                "verdict": parsed_data.get("verdict", "UNVERIFIED"),
                "confidenceScore": min(parsed_data.get("confidence_score", 50), 95),  # Cap at 95%
                "explanation": parsed_data.get("explanation", "Analysis completed using Perplexity AI"),
                "sources": all_sources[:5],  # Limit to 5 sources
                "keyPoints": parsed_data.get("key_points", [])[:5],  # Limit to 5 points
                "analyzedAt": datetime.utcnow(),
                "isFromCache": False,
                "modelVersion": "perplexity-sonar-pro"
            }
            
        except json.JSONDecodeError as e:
            print(f"Failed to parse Perplexity JSON response: {e}")
            # Fallback response
            return {
                "id": str(uuid.uuid4()),
                "inputText": original_text,
                "sourceUrl": source_url,
                "verdict": "UNVERIFIED",
                "confidenceScore": 30,
                "explanation": "Unable to parse detailed analysis from Perplexity AI. The claim requires manual verification with credible sources.",
                "sources": [],
                "keyPoints": ["Analysis parsing failed", "Manual verification recommended"],
                "analyzedAt": datetime.utcnow(),
                "isFromCache": False,
                "modelVersion": "perplexity-sonar-pro-fallback"
            }
        
        except Exception as e:
            print(f"Error parsing Perplexity response: {e}")
            raise e
