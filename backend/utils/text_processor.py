"""
Text processing utilities for content cleaning and validation
Handles Indian language content and common text issues
"""
import re
from typing import List

class TextProcessor:
    """Text processing and validation utilities"""
    
    def __init__(self):
        # Common patterns for cleaning
        self.url_pattern = re.compile(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+')
        self.email_pattern = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
        self.phone_pattern = re.compile(r'(\+91|91)?[-.\s]?[6-9]\d{9}')
        self.excessive_whitespace = re.compile(r'\s+')
        
        # Indian language detection patterns (basic)
        self.hindi_pattern = re.compile(r'[\u0900-\u097F]+')
        self.tamil_pattern = re.compile(r'[\u0B80-\u0BFF]+')
        self.bengali_pattern = re.compile(r'[\u0980-\u09FF]+')
    
    def clean_text(self, text: str) -> str:
        """Clean and normalize text for analysis"""
        if not text or not isinstance(text, str):
            raise ValueError("Text must be a non-empty string")
        
        # Remove excessive whitespace
        text = self.excessive_whitespace.sub(' ', text.strip())
        
        # Remove control characters but keep newlines
        text = ''.join(char for char in text if ord(char) >= 32 or char in '\n\t')
        
        # Normalize quotes
        text = text.replace('"', '"').replace('"', '"')
        text = text.replace(''', "'").replace(''', "'")
        
        # Length validation
        if len(text) < 10:
            raise ValueError("Text too short for meaningful analysis")
        
        if len(text) > 5000:
            text = text[:5000] + "..."
        
        return text
    
    def extract_urls(self, text: str) -> list:
        """Extract URLs from text"""
        return self.url_pattern.findall(text)
    
    def remove_urls(self, text: str) -> str:
        """Remove URLs from text"""
        return self.url_pattern.sub('[URL]', text)
    
    def detect_language(self, text: str) -> str:
        """Basic language detection for Indian languages"""
        if self.hindi_pattern.search(text):
            return "hindi"
        elif self.tamil_pattern.search(text):
            return "tamil"
        elif self.bengali_pattern.search(text):
            return "bengali"
        else:
            return "english"
    
    def is_valid_claim(self, text: str) -> bool:
        """Validate if text is suitable for fact-checking"""
        cleaned = self.clean_text(text)
        
        # Check minimum length
        if len(cleaned) < 10:
            return False
        
        # Check if it's mostly URLs or emails
        urls = self.extract_urls(cleaned)
        emails = self.email_pattern.findall(cleaned)
        
        if len(' '.join(urls + emails)) > len(cleaned) * 0.5:
            return False
        
        # Check for question marks (questions might not be factual claims)
        question_ratio = cleaned.count('?') / len(cleaned.split())
        if question_ratio > 0.3:
            return False
        
        return True
    
    def extract_key_phrases(self, text: str, max_phrases: int = 5) -> list:
        """Extract key phrases for fact-checking focus"""
        # Simple keyword extraction - can be enhanced with NLP
        words = text.split()
        
        # Remove common stop words
        stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have',
            'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should'
        }
        
        # Find potential key phrases (2-3 word combinations)
        phrases = []
        for i in range(len(words) - 1):
            phrase = ' '.join(words[i:i+2]).lower()
            if not any(word in stop_words for word in phrase.split()):
                phrases.append(phrase)
        
        # Return most frequent phrases
        phrase_counts = {}
        for phrase in phrases:
            phrase_counts[phrase] = phrase_counts.get(phrase, 0) + 1
        
        sorted_phrases = sorted(phrase_counts.items(), key=lambda x: x[1], reverse=True)
        return [phrase for phrase, count in sorted_phrases[:max_phrases]]
