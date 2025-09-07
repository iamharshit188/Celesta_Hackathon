"""
Indian news aggregation service using RSS feeds and free APIs
Provides real-time news feed for the Flutter frontend
"""
import httpx
import feedparser
import asyncio
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import re
from urllib.parse import urlparse

class NewsService:
    """Service for aggregating Indian news from multiple sources"""
    
    def __init__(self):
        self.news_sources = {
            "toi": {
                "name": "Times of India",
                "rss": "https://timesofindia.indiatimes.com/rssfeedstopstories.cms",
                "category_rss": {
                    "business": "https://timesofindia.indiatimes.com/rssfeeds/1898055.cms",
                    "sports": "https://timesofindia.indiatimes.com/rssfeeds/4719148.cms",
                    "technology": "https://timesofindia.indiatimes.com/rssfeeds/5880659.cms",
                    "entertainment": "https://timesofindia.indiatimes.com/rssfeeds/1081479906.cms"
                }
            },
            "hindu": {
                "name": "The Hindu",
                "rss": "https://www.thehindu.com/news/national/feeder/default.rss",
                "category_rss": {
                    "business": "https://www.thehindu.com/business/feeder/default.rss",
                    "sports": "https://www.thehindu.com/sport/feeder/default.rss",
                    "technology": "https://www.thehindu.com/sci-tech/technology/feeder/default.rss"
                }
            },
            "ie": {
                "name": "Indian Express",
                "rss": "https://indianexpress.com/print/front-page/feed/",
                "category_rss": {
                    "business": "https://indianexpress.com/section/business/feed/",
                    "sports": "https://indianexpress.com/section/sports/feed/",
                    "technology": "https://indianexpress.com/section/technology/feed/",
                    "entertainment": "https://indianexpress.com/section/entertainment/feed/"
                }
            },
            "ndtv": {
                "name": "NDTV",
                "rss": "http://feeds.feedburner.com/NDTV-LatestNews",
                "category_rss": {
                    "business": "http://feeds.feedburner.com/ndtvprofit-latest",
                    "sports": "http://feeds.feedburner.com/ndtvsports-latest"
                }
            }
        }
        
        self.categories = ["general", "business", "entertainment", "health", "science", "sports", "technology"]
        self.filter_chips = ["Politics", "Tech", "Business", "Sports", "Entertainment"]
    
    async def get_top_headlines(
        self, 
        category: str = "general", 
        page: int = 1, 
        page_size: int = 20
    ) -> Dict[str, Any]:
        """
        Get top headlines from Indian news sources
        """
        try:
            articles = []
            
            if category == "general":
                # Fetch from all main RSS feeds
                for source_key, source_info in self.news_sources.items():
                    source_articles = await self._fetch_rss_articles(
                        source_info["rss"], 
                        source_info["name"],
                        limit=5
                    )
                    articles.extend(source_articles)
            else:
                # Fetch from category-specific RSS feeds
                for source_key, source_info in self.news_sources.items():
                    if category in source_info.get("category_rss", {}):
                        source_articles = await self._fetch_rss_articles(
                            source_info["category_rss"][category],
                            source_info["name"],
                            limit=8
                        )
                        articles.extend(source_articles)
            
            # Sort by publish date (newest first)
            articles.sort(key=lambda x: x.get("publishedAt", ""), reverse=True)
            
            # Apply pagination
            start_idx = (page - 1) * page_size
            end_idx = start_idx + page_size
            paginated_articles = articles[start_idx:end_idx]
            
            return {
                "status": "ok",
                "totalResults": len(articles),
                "articles": paginated_articles
            }
            
        except Exception as e:
            print(f"Error fetching headlines: {e}")
            return {
                "status": "error",
                "message": "Failed to fetch news headlines",
                "articles": []
            }
    
    async def search_news(
        self,
        query: str,
        sort_by: str = "publishedAt",
        page: int = 1,
        page_size: int = 20
    ) -> Dict[str, Any]:
        """
        Search news articles with query
        """
        try:
            # Fetch articles from all sources
            all_articles = []
            
            for source_key, source_info in self.news_sources.items():
                articles = await self._fetch_rss_articles(
                    source_info["rss"],
                    source_info["name"],
                    limit=20
                )
                all_articles.extend(articles)
            
            # Filter articles by query
            query_lower = query.lower()
            filtered_articles = []
            
            for article in all_articles:
                title = article.get("title", "").lower()
                description = article.get("description", "").lower()
                content = article.get("content", "").lower()
                
                if (query_lower in title or 
                    query_lower in description or 
                    query_lower in content):
                    filtered_articles.append(article)
            
            # Sort articles
            if sort_by == "publishedAt":
                filtered_articles.sort(key=lambda x: x.get("publishedAt", ""), reverse=True)
            elif sort_by == "relevancy":
                # Simple relevancy scoring based on query matches
                def relevancy_score(article):
                    score = 0
                    title = article.get("title", "").lower()
                    description = article.get("description", "").lower()
                    
                    score += title.count(query_lower) * 3  # Title matches worth more
                    score += description.count(query_lower) * 1
                    
                    return score
                
                filtered_articles.sort(key=relevancy_score, reverse=True)
            
            # Apply pagination
            start_idx = (page - 1) * page_size
            end_idx = start_idx + page_size
            paginated_articles = filtered_articles[start_idx:end_idx]
            
            return {
                "status": "ok",
                "totalResults": len(filtered_articles),
                "articles": paginated_articles
            }
            
        except Exception as e:
            print(f"Error searching news: {e}")
            return {
                "status": "error",
                "message": "Failed to search news",
                "articles": []
            }
    
    async def _fetch_rss_articles(self, rss_url: str, source_name: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Fetch articles from RSS feed
        """
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(rss_url)
                
                if response.status_code != 200:
                    print(f"RSS fetch failed for {source_name}: {response.status_code}")
                    return []
                
                # Parse RSS feed
                feed = feedparser.parse(response.text)
                articles = []
                
                for entry in feed.entries[:limit]:
                    article = self._parse_rss_entry(entry, source_name)
                    if article:
                        articles.append(article)
                
                return articles
                
        except Exception as e:
            print(f"Error fetching RSS from {source_name}: {e}")
            return []
    
    def _parse_rss_entry(self, entry: Any, source_name: str) -> Optional[Dict[str, Any]]:
        """
        Parse RSS entry into article format matching Flutter frontend
        """
        try:
            # Extract basic information
            title = getattr(entry, 'title', 'No Title')
            description = getattr(entry, 'summary', '') or getattr(entry, 'description', '')
            url = getattr(entry, 'link', '')
            
            # Clean description
            description = re.sub(r'<[^>]+>', '', description)  # Remove HTML tags
            description = description.strip()
            
            # Extract publish date
            published_at = None
            if hasattr(entry, 'published_parsed') and entry.published_parsed:
                published_at = datetime(*entry.published_parsed[:6]).isoformat()
            elif hasattr(entry, 'updated_parsed') and entry.updated_parsed:
                published_at = datetime(*entry.updated_parsed[:6]).isoformat()
            else:
                published_at = datetime.utcnow().isoformat()
            
            # Extract author
            author = getattr(entry, 'author', None)
            
            # Extract image URL
            url_to_image = None
            if hasattr(entry, 'media_content') and entry.media_content:
                url_to_image = entry.media_content[0].get('url')
            elif hasattr(entry, 'enclosures') and entry.enclosures:
                for enclosure in entry.enclosures:
                    if enclosure.type and 'image' in enclosure.type:
                        url_to_image = enclosure.href
                        break
            
            # Categorize article
            category = self._categorize_article(title, description)
            
            return {
                "id": str(hash(url)),  # Simple ID generation
                "title": title,
                "description": description[:200] + "..." if len(description) > 200 else description,
                "content": description,  # RSS usually doesn't have full content
                "url": url,
                "urlToImage": url_to_image,
                "publishedAt": published_at,
                "sourceName": source_name,
                "sourceId": source_name.lower().replace(" ", "_"),
                "author": author,
                "category": category,
                "isBookmarked": False,
                "cachedAt": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            print(f"Error parsing RSS entry: {e}")
            return None
    
    def _categorize_article(self, title: str, description: str) -> str:
        """
        Simple categorization based on keywords
        """
        text = (title + " " + description).lower()
        
        # Business keywords
        business_keywords = ["economy", "market", "stock", "business", "finance", "bank", "rupee", "gdp", "inflation"]
        if any(keyword in text for keyword in business_keywords):
            return "business"
        
        # Sports keywords
        sports_keywords = ["cricket", "football", "hockey", "olympics", "match", "tournament", "player", "team"]
        if any(keyword in text for keyword in sports_keywords):
            return "sports"
        
        # Technology keywords
        tech_keywords = ["technology", "tech", "ai", "artificial intelligence", "software", "app", "digital", "cyber"]
        if any(keyword in text for keyword in tech_keywords):
            return "technology"
        
        # Entertainment keywords
        entertainment_keywords = ["bollywood", "movie", "film", "actor", "actress", "music", "entertainment", "celebrity"]
        if any(keyword in text for keyword in entertainment_keywords):
            return "entertainment"
        
        # Health keywords
        health_keywords = ["health", "medical", "doctor", "hospital", "disease", "medicine", "covid", "vaccine"]
        if any(keyword in text for keyword in health_keywords):
            return "health"
        
        # Default to general
        return "general"
