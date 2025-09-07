import asyncio
import aiohttp
from typing import List, Tuple, Optional
from urllib.parse import urlparse, urljoin
from bs4 import BeautifulSoup
from newspaper import Article
import requests
from loguru import logger

from ..utils.config import settings
from ..models.schemas import FactCheckSource

class WebCrawlerService:
    """Service for extracting content from URLs and performing fact-checking searches."""
    
    def __init__(self):
        self.session = None
        self.is_initialized = False
        
    async def initialize(self):
        """Initialize the web crawler service."""
        try:
            logger.info("Initializing web crawler service...")
            
            # Create aiohttp session
            timeout = aiohttp.ClientTimeout(total=30)
            connector = aiohttp.TCPConnector(limit=10, limit_per_host=3)
            
            self.session = aiohttp.ClientSession(
                timeout=timeout,
                connector=connector,
                headers={
                    'User-Agent': 'FakeNewsDetector/1.0 (Educational Purpose)'
                }
            )
            
            self.is_initialized = True
            logger.info("Web crawler service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize web crawler service: {e}")
            raise
    
    async def extract_article_content(self, url: str) -> Tuple[str, str, dict]:
        """
        Extract content from a news article URL.
        
        Args:
            url: The URL to extract content from
            
        Returns:
            Tuple of (title, content, metadata)
        """
        if not self.is_initialized:
            raise RuntimeError("Web crawler service not initialized")
        
        try:
            # First try with newspaper3k
            article_data = await asyncio.to_thread(self._extract_with_newspaper, url)
            
            if article_data['content']:
                logger.info(f"Successfully extracted article from {url}")
                return article_data['title'], article_data['content'], article_data['metadata']
            
            # Fallback to BeautifulSoup
            logger.info("Newspaper3k failed, trying BeautifulSoup fallback")
            return await self._extract_with_beautifulsoup(url)
            
        except Exception as e:
            logger.error(f"Content extraction failed for {url}: {e}")
            return "", f"Failed to extract content: {str(e)}", {}
    
    def _extract_with_newspaper(self, url: str) -> dict:
        """Extract article using newspaper3k."""
        try:
            article = Article(url)
            article.download()
            article.parse()
            
            return {
                'title': article.title or '',
                'content': article.text or '',
                'metadata': {
                    'authors': article.authors,
                    'publish_date': article.publish_date.isoformat() if article.publish_date else None,
                    'source_url': url,
                    'top_image': article.top_image,
                    'summary': article.summary if hasattr(article, 'summary') else ''
                }
            }
        except Exception as e:
            logger.warning(f"Newspaper3k extraction failed: {e}")
            return {'title': '', 'content': '', 'metadata': {}}
    
    async def _extract_with_beautifulsoup(self, url: str) -> Tuple[str, str, dict]:
        """Extract content using BeautifulSoup as fallback."""
        try:
            async with self.session.get(url) as response:
                if response.status != 200:
                    raise ValueError(f"HTTP {response.status}")
                
                html = await response.text()
                soup = BeautifulSoup(html, 'html.parser')
                
                # Extract title
                title_tag = soup.find('title')
                title = title_tag.text.strip() if title_tag else ''
                
                # Extract main content
                content = self._extract_main_content(soup)
                
                # Basic metadata
                metadata = {
                    'source_url': url,
                    'domain': urlparse(url).netloc,
                    'extraction_method': 'beautifulsoup'
                }
                
                return title, content, metadata
                
        except Exception as e:
            logger.error(f"BeautifulSoup extraction failed: {e}")
            return "", f"Extraction failed: {str(e)}", {}
    
    def _extract_main_content(self, soup: BeautifulSoup) -> str:
        """Extract main content from HTML using heuristics."""
        # Remove unwanted elements
        for element in soup(['script', 'style', 'nav', 'header', 'footer', 'aside']):
            element.decompose()
        
        # Try common content selectors
        content_selectors = [
            'article',
            '.article-body',
            '.post-content',
            '.entry-content',
            '.content',
            'main',
            '.story-body'
        ]
        
        for selector in content_selectors:
            content_elem = soup.select_one(selector)
            if content_elem:
                return content_elem.get_text(separator=' ', strip=True)
        
        # Fallback: extract from body
        body = soup.find('body')
        if body:
            return body.get_text(separator=' ', strip=True)
        
        return soup.get_text(separator=' ', strip=True)
    
    async def search_fact_check_sources(self, query: str, limit: int = 5) -> List[FactCheckSource]:
        """
        Search for fact-checking sources related to the query.
        
        Args:
            query: The search query
            limit: Maximum number of sources to return
            
        Returns:
            List of fact-check sources
        """
        if not self.is_initialized:
            raise RuntimeError("Web crawler service not initialized")
        
        try:
            # Try multiple fact-checking approaches
            sources = []
            
            # Search fact-checking websites
            fact_check_sites = [
                'snopes.com',
                'factcheck.org',
                'politifact.com',
                'reuters.com/fact-check',
                'apnews.com/hub/ap-fact-check'
            ]
            
            # Try Perplexity API first if available
            if settings.PERPLEXITY_API_KEY:
                perplexity_sources = await self._perplexity_fact_check(query, limit)
                if perplexity_sources:
                    sources.extend(perplexity_sources)
                    logger.info(f"Found {len(perplexity_sources)} sources from Perplexity API")
                    return sources[:limit]
            
            # Use Google Custom Search if API key is available
            if settings.GOOGLE_SEARCH_API_KEY and settings.GOOGLE_SEARCH_ENGINE_ID:
                sources.extend(await self._google_fact_check_search(query, limit))
            else:
                # Fallback: search specific fact-check sites
                for site in fact_check_sites[:min(3, limit)]:
                    try:
                        site_sources = await self._search_site(site, query)
                        sources.extend(site_sources)
                        if len(sources) >= limit:
                            break
                    except Exception as e:
                        logger.warning(f"Failed to search {site}: {e}")
            
            logger.info(f"Found {len(sources)} fact-check sources for query: {query}")
            return sources[:limit]
            
        except Exception as e:
            logger.error(f"Fact-check search failed: {e}")
            return []
    
    async def _google_fact_check_search(self, query: str, limit: int) -> List[FactCheckSource]:
        """Search using Google Custom Search API."""
        try:
            search_url = "https://www.googleapis.com/customsearch/v1"
            params = {
                'key': settings.GOOGLE_SEARCH_API_KEY,
                'cx': settings.GOOGLE_SEARCH_ENGINE_ID,
                'q': f"{query} fact check",
                'num': min(limit, 10)
            }
            
            async with self.session.get(search_url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    sources = []
                    
                    for item in data.get('items', []):
                        source = FactCheckSource(
                            title=item.get('title', ''),
                            url=item.get('link', ''),
                            summary=item.get('snippet', ''),
                            reliability=0.8,  # High reliability for fact-check sites
                            domain=urlparse(item.get('link', '')).netloc
                        )
                        sources.append(source)
                    
                    return sources
                else:
                    logger.warning(f"Google Search API returned {response.status}")
                    return []
                    
        except Exception as e:
            logger.error(f"Google fact-check search failed: {e}")
            return []
    
    async def _perplexity_fact_check(self, query: str, limit: int = 5) -> List[FactCheckSource]:
        """Use Perplexity API for fact-checking."""
        try:
            # Perplexity API endpoint
            api_url = "https://api.perplexity.ai/chat/completions"
            
            # Prepare the prompt for fact-checking
            prompt = f"Fact check this claim and provide reliable sources: '{query}'"
            
            # API request payload
            payload = {
                "model": "sonar-medium-online",  # Use Groq's model instead of Perplexity's
                "messages": [
                    {"role": "system", "content": "You are a helpful fact-checking assistant. Provide factual information with reliable sources."}, 
                    {"role": "user", "content": prompt}
                ],
                "max_tokens": 1024,
                "temperature": 0.2
            }
            
            headers = {
                "Authorization": f"Bearer {settings.PERPLEXITY_API_KEY}",
                "Content-Type": "application/json"
            }
            
            async with await self.session.post(api_url, json=payload, headers=headers) as response:
                if response.status == 200:
                    data = await response.json()
                    content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                    
                    # Extract sources from the response
                    sources = []
                    lines = content.split("\n")
                    current_source = {}
                    
                    for line in lines:
                        if line.lower().startswith(("source:", "reference:", "[source]", "[reference]")):
                            if "url" in current_source and "title" in current_source:
                                sources.append(FactCheckSource(
                                    title=current_source.get("title", ""),
                                    url=current_source.get("url", ""),
                                    summary=current_source.get("summary", ""),
                                    reliability=0.9,  # High reliability for Perplexity
                                    domain=urlparse(current_source.get("url", "")).netloc
                                ))
                                if len(sources) >= limit:
                                    break
                            current_source = {"title": line.split(":", 1)[1].strip() if ":" in line else ""}
                        elif "http" in line and "title" in current_source and "url" not in current_source:
                            # Extract URL from the line
                            words = line.split()
                            for word in words:
                                if word.startswith("http"):
                                    current_source["url"] = word.strip(".,()[]")
                                    break
                        elif "title" in current_source and "url" in current_source and "summary" not in current_source:
                            current_source["summary"] = line
                    
                    # Add the last source if it exists
                    if "url" in current_source and "title" in current_source and len(sources) < limit:
                        sources.append(FactCheckSource(
                            title=current_source.get("title", ""),
                            url=current_source.get("url", ""),
                            summary=current_source.get("summary", ""),
                            reliability=0.9,
                            domain=urlparse(current_source.get("url", "")).netloc
                        ))
                    
                    return sources
                else:
                    logger.warning(f"Perplexity API returned status {response.status}")
                    return []
        
        except Exception as e:
            logger.error(f"Perplexity fact-check failed: {e}")
            return []
    
    async def _search_site(self, site: str, query: str) -> List[FactCheckSource]:
        """Search a specific fact-checking site."""
        try:
            # Simple site search using DuckDuckGo (no API key needed)
            search_query = f"site:{site} {query}"
            search_url = f"https://duckduckgo.com/html/?q={search_query}"
            
            async with await self.session.get(search_url) as response:
                if response.status == 200:
                    html = await response.text()
                    soup = BeautifulSoup(html, 'html.parser')
                    
                    sources = []
                    for result in soup.select('.result')[:2]:  # Get top 2 results
                        title_elem = result.select_one('.result__title a')
                        snippet_elem = result.select_one('.result__snippet')
                        
                        if title_elem and snippet_elem:
                            source = FactCheckSource(
                                title=title_elem.get_text(strip=True),
                                url=title_elem.get('href', ''),
                                summary=snippet_elem.get_text(strip=True),
                                reliability=0.7,  # Good reliability
                                domain=site
                            )
                            sources.append(source)
                    
                    return sources
                    
        except Exception as e:
            logger.error(f"Site search failed for {site}: {e}")
            
        return []
    
    async def get_status(self) -> dict:
        """Get the current status of the web crawler service."""
        return {
            "name": "web_crawler",
            "status": "loaded" if self.is_initialized else "not_loaded",
            "has_google_api": bool(settings.GOOGLE_SEARCH_API_KEY),
            "session_active": self.session is not None and not self.session.closed
        }
    
    async def cleanup(self):
        """Clean up resources."""
        if self.session:
            await self.session.close()

# Create global instance
web_crawler_service = WebCrawlerService()
