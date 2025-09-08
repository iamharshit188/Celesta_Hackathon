"""
Offline Indian News Service using Hugging Face models
Provides fallback news functionality when RSS feeds are unavailable
"""
import os
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
import torch
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.cache_manager import CacheManager

logger = logging.getLogger(__name__)

class OfflineIndianNewsService:
    def __init__(self):
        self.cache_manager = CacheManager()
        self.model = None
        self.tokenizer = None
        self.generator = None
        self.model_name = "microsoft/DialoGPT-medium"  # Lightweight conversational model
        self._initialize_model()
        
        # Indian news topics and keywords for generating relevant content
        self.indian_topics = [
            "Indian politics", "Modi government", "BJP", "Congress", "AAP",
            "Indian economy", "GDP growth", "inflation", "stock market",
            "Bollywood", "cricket", "IPL", "Indian cinema",
            "technology in India", "startup ecosystem", "digital India",
            "monsoon", "agriculture", "farmers", "rural development",
            "education policy", "healthcare", "COVID-19 India",
            "Kashmir", "border security", "China relations", "Pakistan",
            "state elections", "assembly polls", "Lok Sabha"
        ]
        
        # Sample Indian news templates for offline mode
        self.news_templates = [
            {
                "title": "Government Announces New {policy} Initiative for {sector}",
                "description": "The Indian government has launched a comprehensive {policy} program aimed at boosting {sector} development across the country.",
                "category": "general"
            },
            {
                "title": "Indian {sector} Sector Shows Strong Growth in Q{quarter}",
                "description": "Latest economic data reveals significant expansion in India's {sector} industry, with experts predicting continued growth.",
                "category": "business"
            },
            {
                "title": "Breakthrough in Indian {field} Research Gains International Recognition",
                "description": "Indian scientists and researchers have made significant advances in {field}, earning praise from the global scientific community.",
                "category": "science"
            },
            {
                "title": "Major {sport} Tournament Concludes with Record Viewership",
                "description": "The latest {sport} championship has set new records for audience engagement across India and international markets.",
                "category": "sports"
            },
            {
                "title": "New {technology} Innovation Launched by Indian Startup",
                "description": "A promising Indian startup has unveiled cutting-edge {technology} solutions that could transform the industry landscape.",
                "category": "technology"
            }
        ]

    def _initialize_model(self):
        """Initialize the Hugging Face model for text generation"""
        try:
            # Check if model is already cached
            model_cache_key = f"hf_model_{self.model_name.replace('/', '_')}"
            
            # Use a smaller, more efficient model for news generation
            logger.info(f"Initializing Hugging Face model: {self.model_name}")
            
            # Initialize text generation pipeline
            self.generator = pipeline(
                "text-generation",
                model=self.model_name,
                tokenizer=self.model_name,
                max_length=200,
                do_sample=True,
                temperature=0.7,
                pad_token_id=50256,  # GPT-2 pad token
                device=-1  # Use CPU to avoid GPU memory issues
            )
            
            logger.info("Hugging Face model initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Hugging Face model: {e}")
            self.generator = None

    def generate_offline_news(self, category: str = "general", count: int = 10) -> List[Dict[str, Any]]:
        """Generate offline news articles using templates and AI model"""
        try:
            # First try to get cached offline news
            cache_key = f"offline_news_{category}_{count}"
            cached_news = self.cache_manager.get(cache_key, "news")
            
            if cached_news:
                logger.info(f"Returning cached offline news for category: {category}")
                return cached_news
            
            news_articles = []
            
            # Generate news using templates
            template_articles = self._generate_template_news(category, count // 2)
            news_articles.extend(template_articles)
            
            # Generate AI-powered news if model is available
            if self.generator and len(news_articles) < count:
                ai_articles = self._generate_ai_news(category, count - len(news_articles))
                news_articles.extend(ai_articles)
            
            # Fill remaining with more template articles if needed
            while len(news_articles) < count:
                additional = self._generate_template_news(category, count - len(news_articles))
                news_articles.extend(additional)
            
            # Cache the generated news for 1 hour
            self.cache_manager.set(cache_key, news_articles[:count], "news", ttl_hours=1)
            
            logger.info(f"Generated {len(news_articles[:count])} offline news articles for category: {category}")
            return news_articles[:count]
            
        except Exception as e:
            logger.error(f"Error generating offline news: {e}")
            return self._get_fallback_news(category, count)

    def _generate_template_news(self, category: str, count: int) -> List[Dict[str, Any]]:
        """Generate news using predefined templates"""
        articles = []
        
        # Filter templates by category
        relevant_templates = [t for t in self.news_templates if t["category"] == category or category == "general"]
        if not relevant_templates:
            relevant_templates = self.news_templates
        
        import random
        
        for i in range(count):
            template = random.choice(relevant_templates)
            
            # Fill template with Indian context
            policy_terms = ["digital", "economic", "social", "infrastructure", "education"]
            sector_terms = ["agriculture", "technology", "healthcare", "manufacturing", "services"]
            field_terms = ["artificial intelligence", "renewable energy", "biotechnology", "space technology"]
            sport_terms = ["cricket", "hockey", "badminton", "kabaddi"]
            tech_terms = ["AI", "blockchain", "fintech", "edtech"]
            
            title = template["title"].format(
                policy=random.choice(policy_terms),
                sector=random.choice(sector_terms),
                quarter=random.randint(1, 4),
                field=random.choice(field_terms),
                sport=random.choice(sport_terms),
                technology=random.choice(tech_terms)
            )
            
            description = template["description"].format(
                policy=random.choice(policy_terms),
                sector=random.choice(sector_terms),
                quarter=random.randint(1, 4),
                field=random.choice(field_terms),
                sport=random.choice(sport_terms),
                technology=random.choice(tech_terms)
            )
            
            article = {
                "id": f"offline_{category}_{i}_{int(datetime.now().timestamp())}",
                "title": title,
                "description": description,
                "content": f"{description} This development is expected to have significant implications for India's growth trajectory and international standing.",
                "url": f"https://offline-news.example.com/article/{i}",
                "urlToImage": None,
                "publishedAt": (datetime.now() - timedelta(hours=random.randint(1, 24))).isoformat(),
                "sourceName": "Offline News Service",
                "sourceId": "offline_service",
                "author": "AI News Generator",
                "category": category,
                "isBookmarked": False,
                "cachedAt": datetime.now().isoformat()
            }
            
            articles.append(article)
        
        return articles

    def _generate_ai_news(self, category: str, count: int) -> List[Dict[str, Any]]:
        """Generate news using AI model"""
        articles = []
        
        if not self.generator:
            return articles
        
        try:
            import random
            
            for i in range(count):
                # Create a prompt based on category and Indian context
                topic = random.choice(self.indian_topics)
                prompt = f"Breaking news from India: {topic}"
                
                # Generate text using the model
                generated = self.generator(
                    prompt,
                    max_length=150,
                    num_return_sequences=1,
                    temperature=0.7,
                    do_sample=True
                )
                
                generated_text = generated[0]['generated_text']
                
                # Extract title and description from generated text
                lines = generated_text.split('\n')
                title = lines[0].replace(prompt, "").strip()
                if not title:
                    title = f"AI Generated News: {topic}"
                
                description = " ".join(lines[1:3]) if len(lines) > 1 else f"Latest developments in {topic} from across India."
                
                article = {
                    "id": f"ai_generated_{category}_{i}_{int(datetime.now().timestamp())}",
                    "title": title[:100],  # Limit title length
                    "description": description[:200],  # Limit description length
                    "content": generated_text[:500],  # Limit content length
                    "url": f"https://ai-news.example.com/article/{i}",
                    "urlToImage": None,
                    "publishedAt": (datetime.now() - timedelta(hours=random.randint(1, 12))).isoformat(),
                    "sourceName": "AI News Generator",
                    "sourceId": "ai_generator",
                    "author": "AI Assistant",
                    "category": category,
                    "isBookmarked": False,
                    "cachedAt": datetime.now().isoformat()
                }
                
                articles.append(article)
                
        except Exception as e:
            logger.error(f"Error generating AI news: {e}")
        
        return articles

    def _get_fallback_news(self, category: str, count: int) -> List[Dict[str, Any]]:
        """Provide basic fallback news when all else fails"""
        fallback_articles = []
        
        for i in range(count):
            article = {
                "id": f"fallback_{category}_{i}",
                "title": f"Indian News Update #{i+1}",
                "description": f"Stay updated with the latest developments in {category} news from across India.",
                "content": f"This is a fallback news article for the {category} category. Real news will be available when internet connectivity is restored.",
                "url": "https://example.com/offline",
                "urlToImage": None,
                "publishedAt": (datetime.now() - timedelta(hours=i+1)).isoformat(),
                "sourceName": "Offline Service",
                "sourceId": "offline",
                "author": "System",
                "category": category,
                "isBookmarked": False,
                "cachedAt": datetime.now().isoformat()
            }
            fallback_articles.append(article)
        
        return fallback_articles

    def is_model_available(self) -> bool:
        """Check if the AI model is available for use"""
        return self.generator is not None

    def get_model_info(self) -> Dict[str, Any]:
        """Get information about the loaded model"""
        return {
            "model_name": self.model_name,
            "is_available": self.is_model_available(),
            "device": "cpu",
            "status": "ready" if self.is_model_available() else "unavailable"
        }
