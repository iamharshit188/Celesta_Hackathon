import uuid
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from loguru import logger

from ..models.schemas import (
    NewsArticle,
    NewsFeedResponse,
    SearchNewsRequest,
    SearchNewsResponse
)

router = APIRouter()

# Mock news data for demonstration - Tailored for Indian audience
MOCK_NEWS_DATA = [
    {
        "id": str(uuid.uuid4()),
        "title": "RBI Announces New Measures to Control Inflation",
        "summary": "The Reserve Bank of India has introduced a series of monetary policy measures aimed at controlling inflation while supporting economic growth.",
        "source": "Economic Times",
        "image_url": "https://example.com/rbi-policy.jpg",
        "url": "https://example.com/rbi-inflation-measures",
        "published_at": datetime.now() - timedelta(hours=10),
        "category": "Business",
        "credibility_score": 0.91
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Major Infrastructure Project Launched in Maharashtra",
        "summary": "The state government has inaugurated a significant infrastructure development project that aims to improve transportation and connectivity across Maharashtra.",
        "source": "Hindustan Times",
        "image_url": "https://example.com/maharashtra-infrastructure.jpg",
        "url": "https://example.com/maharashtra-infrastructure-project",
        "published_at": datetime.now() - timedelta(hours=12),
        "category": "Regional",
        "credibility_score": 0.89
    },
    {
        "id": str(uuid.uuid4()),
        "title": "ISRO Successfully Launches Next-Generation Earth Observation Satellite",
        "summary": "The Indian Space Research Organisation (ISRO) has successfully launched its latest earth observation satellite, enhancing India's capabilities in weather forecasting and disaster management.",
        "source": "The Hindu",
        "image_url": "https://example.com/isro-satellite-launch.jpg",
        "url": "https://example.com/isro-satellite-launch-success",
        "published_at": datetime.now() - timedelta(hours=2),
        "category": "Tech & Science",
        "credibility_score": 0.95
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Government Announces New Education Policy Reforms",
        "summary": "The Ministry of Education has unveiled comprehensive reforms to the national education policy, focusing on skill development and digital learning initiatives across India.",
        "source": "The Times of India",
        "image_url": "https://example.com/education-policy.jpg",
        "url": "https://example.com/education-policy-reforms",
        "published_at": datetime.now() - timedelta(hours=4),
        "category": "Politics",
        "credibility_score": 0.88
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Indian Researchers Develop Low-Cost AI Solution for Rural Healthcare",
        "summary": "A team of researchers from IIT Delhi has created an affordable AI-powered diagnostic tool designed to improve healthcare access in rural India.",
        "source": "India Today",
        "image_url": "https://example.com/rural-healthcare-ai.jpg",
        "url": "https://example.com/rural-healthcare-ai-solution",
        "published_at": datetime.now() - timedelta(hours=6),
        "category": "Tech & Science",
        "credibility_score": 0.87
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Indian Cricket Team Announces Squad for Upcoming Series",
        "summary": "The BCCI has announced the Indian cricket team squad for the upcoming international series, featuring several new players and strategic changes to the lineup.",
        "source": "ESPNcricinfo",
        "image_url": "https://example.com/cricket-team-announcement.jpg",
        "url": "https://example.com/indian-cricket-team-squad",
        "published_at": datetime.now() - timedelta(hours=8),
        "category": "Sports",
        "credibility_score": 0.93
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Breakthrough in Quantum Computing Brings Practical Applications Closer",
        "summary": "Major tech companies announce significant advances in quantum error correction, paving the way for real-world quantum applications.",
        "source": "Quantum Computing Weekly",
        "image_url": "https://example.com/quantum-computer.jpg",
        "url": "https://example.com/quantum-breakthrough-2024",
        "published_at": datetime.now() - timedelta(hours=12),
        "category": "Tech & Science",
        "credibility_score": 0.87
    },
    {
        "id": str(uuid.uuid4()),
        "title": "Global Health Initiative Launches to Combat Infectious Diseases",
        "summary": "International coalition announces $10 billion investment in pandemic preparedness and infectious disease research.",
        "source": "Health Policy Institute",
        "image_url": "https://example.com/health-initiative.jpg",
        "url": "https://example.com/global-health-initiative",
        "published_at": datetime.now() - timedelta(hours=16),
        "category": "Health",
        "credibility_score": 0.89
    }
]

@router.get("/feed", response_model=NewsFeedResponse)
async def get_news_feed(
    category: str = Query("For You", description="News category"),
    limit: int = Query(20, ge=1, le=100, description="Number of articles to return")
):
    """Get news feed for the specified category."""
    try:
        logger.info(f"News feed request: category={category}, limit={limit}")
        
        # Filter articles by category
        if category == "For You":
            # Return all articles for personalized feed
            filtered_articles = MOCK_NEWS_DATA
        elif category == "Top Stories":
            # Return highest credibility articles
            filtered_articles = sorted(MOCK_NEWS_DATA, key=lambda x: x["credibility_score"], reverse=True)
        elif category == "Indian Politics":
            # Filter for Indian politics news
            filtered_articles = [article for article in MOCK_NEWS_DATA 
                               if article["category"] == "Politics" 
                               or "government" in article["summary"].lower() 
                               or "ministry" in article["summary"].lower()]
        elif category == "Technology":
            # Filter for tech news with focus on Indian tech
            filtered_articles = [article for article in MOCK_NEWS_DATA 
                               if article["category"] == "Tech & Science" 
                               or "ISRO" in article["summary"] 
                               or "IIT" in article["summary"]]
        elif category == "Regional":
            # Filter for regional news
            filtered_articles = [article for article in MOCK_NEWS_DATA 
                               if article["category"] == "Regional"]
        elif category == "Business":
            # Filter for business news
            filtered_articles = [article for article in MOCK_NEWS_DATA 
                               if article["category"] == "Business" 
                               or "RBI" in article["summary"]]
        else:
            # Filter by specific category
            filtered_articles = [article for article in MOCK_NEWS_DATA if article["category"] == category]
        
        # Convert to NewsArticle objects
        articles = []
        for article_data in filtered_articles[:limit]:
            article = NewsArticle(
                id=article_data["id"],
                title=article_data["title"],
                summary=article_data["summary"],
                source=article_data["source"],
                image_url=article_data["image_url"],
                url=article_data["url"],
                published_at=article_data["published_at"],
                category=article_data["category"],
                credibility_score=article_data["credibility_score"]
            )
            articles.append(article)
        
        response = NewsFeedResponse(
            articles=articles,
            total_count=len(filtered_articles),
            category=category,
            has_more=len(filtered_articles) > limit
        )
        
        logger.info(f"Returning {len(articles)} articles for category '{category}'")
        return response
        
    except Exception as e:
        logger.error(f"News feed request failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch news feed: {str(e)}")

@router.post("/search", response_model=SearchNewsResponse)
async def search_news(request: SearchNewsRequest):
    """Search news articles by query."""
    try:
        start_time = datetime.now()
        logger.info(f"News search request: '{request.query}', limit={request.limit}")
        
        query_lower = request.query.lower()
        
        # Simple text search in titles and summaries
        matching_articles = []
        for article_data in MOCK_NEWS_DATA:
            title_lower = article_data["title"].lower()
            summary_lower = article_data["summary"].lower()
            
            # Check if query matches title or summary
            if (query_lower in title_lower or 
                query_lower in summary_lower or 
                any(word in title_lower or word in summary_lower for word in query_lower.split())):
                
                # Apply category filter if specified
                if request.category and article_data["category"] != request.category:
                    continue
                
                article = NewsArticle(
                    id=article_data["id"],
                    title=article_data["title"],
                    summary=article_data["summary"],
                    source=article_data["source"],
                    image_url=article_data["image_url"],
                    url=article_data["url"],
                    published_at=article_data["published_at"],
                    category=article_data["category"],
                    credibility_score=article_data["credibility_score"]
                )
                matching_articles.append(article)
        
        # Limit results
        limited_articles = matching_articles[:request.limit]
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        response = SearchNewsResponse(
            articles=limited_articles,
            query=request.query,
            total_count=len(matching_articles),
            took_ms=int(processing_time)
        )
        
        logger.info(f"Search returned {len(limited_articles)} articles in {processing_time:.2f}ms")
        return response
        
    except Exception as e:
        logger.error(f"News search failed: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@router.get("/categories")
async def get_news_categories():
    """Get available news categories."""
    try:
        # Extract unique categories from mock data
        categories = list(set(article["category"] for article in MOCK_NEWS_DATA))
        categories.sort()
        
        # Add special categories
        all_categories = ["For You", "Top Stories"] + categories
        
        return {
            "categories": all_categories,
            "total_count": len(all_categories)
        }
        
    except Exception as e:
        logger.error(f"Failed to get categories: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get categories: {str(e)}")

@router.get("/trending")
async def get_trending_topics():
    """Get trending topics based on article analysis."""
    try:
        # Mock trending topics
        trending_topics = [
            {"topic": "AI Medical Diagnosis", "count": 15, "category": "Tech & Science"},
            {"topic": "Climate Change", "count": 12, "category": "Politics"},
            {"topic": "Olympic Sustainability", "count": 8, "category": "Sports"},
            {"topic": "Quantum Computing", "count": 6, "category": "Tech & Science"},
            {"topic": "Global Health", "count": 5, "category": "Health"}
        ]
        
        return {
            "trending_topics": trending_topics,
            "updated_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get trending topics: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get trending topics: {str(e)}")
