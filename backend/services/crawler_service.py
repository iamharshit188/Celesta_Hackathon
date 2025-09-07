"""
Web crawling service for extracting content from Indian news websites
Supports major Indian news sources with smart content extraction
"""
import httpx
import asyncio
from bs4 import BeautifulSoup
from readability import Document
from typing import Dict, Any, Optional
import re
from urllib.parse import urlparse, urljoin
import os

class CrawlerService:
    """Service for intelligent web content extraction"""
    
    def __init__(self):
        self.supported_domains = [
            "timesofindia.indiatimes.com",
            "thehindu.com", 
            "indianexpress.com",
            "ndtv.com",
            "hindustantimes.com",
            "news18.com",
            "aajtak.in",
            "republicworld.com",
            "zeenews.india.com",
            "indiatoday.in"
        ]
        
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
    
    async def extract_content(self, url: str) -> Dict[str, Any]:
        """
        Extract clean content from news URLs
        """
        try:
            # Validate URL
            if not self._is_valid_url(url):
                raise Exception("Invalid URL format")
            
            # Check if domain is supported
            domain = urlparse(url).netloc.lower()
            is_supported = any(supported in domain for supported in self.supported_domains)
            
            # Fetch content
            async with httpx.AsyncClient(
                timeout=30.0,
                headers=self.headers,
                follow_redirects=True
            ) as client:
                response = await client.get(url)
                
                if response.status_code != 200:
                    raise Exception(f"HTTP {response.status_code}: Failed to fetch content")
                
                html_content = response.text
            
            # Extract content using readability
            doc = Document(html_content)
            title = doc.title()
            content = doc.summary()
            
            # Clean extracted content
            cleaned_content = self._clean_html_content(content)
            
            # Extract metadata
            metadata = self._extract_metadata(html_content, url)
            
            # Validate content quality
            if len(cleaned_content.strip()) < 100:
                raise Exception("Extracted content too short or empty")
            
            return {
                "extractedText": f"{title}\n\n{cleaned_content}",
                "metadata": {
                    "title": title,
                    "url": url,
                    "domain": domain,
                    "is_supported_domain": is_supported,
                    "content_length": len(cleaned_content),
                    **metadata
                }
            }
            
        except Exception as e:
            # Return error with partial information
            return {
                "extractedText": f"Failed to extract content from: {url}\n\nError: {str(e)}",
                "metadata": {
                    "url": url,
                    "error": str(e),
                    "extraction_failed": True
                }
            }
    
    def _is_valid_url(self, url: str) -> bool:
        """Validate URL format"""
        try:
            result = urlparse(url)
            return all([result.scheme, result.netloc])
        except:
            return False
    
    def _clean_html_content(self, html_content: str) -> str:
        """Clean HTML content and extract text"""
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Remove unwanted elements
            for element in soup(['script', 'style', 'nav', 'header', 'footer', 'aside', 'advertisement']):
                element.decompose()
            
            # Remove elements with common ad/navigation classes
            ad_classes = ['advertisement', 'ad-', 'sidebar', 'related-articles', 'social-share', 'comments']
            for class_name in ad_classes:
                for element in soup.find_all(attrs={'class': re.compile(class_name, re.I)}):
                    element.decompose()
            
            # Extract text
            text = soup.get_text()
            
            # Clean text
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            text = ' '.join(chunk for chunk in chunks if chunk)
            
            # Remove excessive whitespace
            text = re.sub(r'\s+', ' ', text).strip()
            
            return text
            
        except Exception as e:
            print(f"HTML cleaning error: {e}")
            return "Content extraction failed"
    
    def _extract_metadata(self, html_content: str, url: str) -> Dict[str, Any]:
        """Extract metadata from HTML"""
        metadata = {}
        
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Extract author
            author_selectors = [
                'meta[name="author"]',
                'meta[property="article:author"]',
                '.author',
                '.byline',
                '[rel="author"]'
            ]
            
            for selector in author_selectors:
                element = soup.select_one(selector)
                if element:
                    if element.name == 'meta':
                        metadata['author'] = element.get('content', '').strip()
                    else:
                        metadata['author'] = element.get_text().strip()
                    break
            
            # Extract publish date
            date_selectors = [
                'meta[property="article:published_time"]',
                'meta[name="publishdate"]',
                'meta[name="date"]',
                'time[datetime]',
                '.publish-date',
                '.date'
            ]
            
            for selector in date_selectors:
                element = soup.select_one(selector)
                if element:
                    if element.name == 'meta':
                        metadata['published_date'] = element.get('content', '').strip()
                    elif element.name == 'time':
                        metadata['published_date'] = element.get('datetime', '').strip()
                    else:
                        metadata['published_date'] = element.get_text().strip()
                    break
            
            # Extract description
            description_selectors = [
                'meta[name="description"]',
                'meta[property="og:description"]',
                'meta[name="twitter:description"]'
            ]
            
            for selector in description_selectors:
                element = soup.select_one(selector)
                if element:
                    metadata['description'] = element.get('content', '').strip()
                    break
            
            # Extract keywords/tags
            keywords_element = soup.select_one('meta[name="keywords"]')
            if keywords_element:
                metadata['keywords'] = keywords_element.get('content', '').strip()
            
        except Exception as e:
            print(f"Metadata extraction error: {e}")
        
        return metadata
