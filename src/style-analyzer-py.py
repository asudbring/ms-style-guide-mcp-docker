#!/usr/bin/env python3
"""
Microsoft Style Guide Analyzer - Web-Enabled Version
Extracted from fastmcp_style_server_web.py for HTTP deployment
"""

import asyncio
import json
import logging
import re
from typing import Any, Dict, List, Optional
import aiohttp

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WebEnabledStyleGuideAnalyzer:
    """Web-enabled analyzer that fetches live guidance from Microsoft Style Guide."""
    
    def __init__(self):
        """Initialize the analyzer with web capabilities."""
        self.style_guide_base_url = "https://learn.microsoft.com/en-us/style-guide"
        self.session = None
        
        # Core style guide URLs for live content
        self.core_urls = {
            "voice_tone": f"{self.style_guide_base_url}/brand-voice-above-all-simple-human",
            "top_tips": f"{self.style_guide_base_url}/top-10-tips-style-voice",
            "bias_free": f"{self.style_guide_base_url}/bias-free-communication",
            "writing_tips": f"{self.style_guide_base_url}/global-communications/writing-tips",
            "welcome": f"{self.style_guide_base_url}/welcome/",
            "word_list": f"{self.style_guide_base_url}/a-z-word-list-term-collections"
        }
        
        # Core style patterns (same as offline version)
        self.patterns = {
            "contractions": r"\b(it's|you're|we're|don't|can't|won't|let's|you'll|we'll)\b",
            "passive_voice": r"\b(is|are|was|were|been|be)\s+\w*ed\b",
            "long_sentences": r"[.!?]+\s*[A-Z][^.!?]{100,}[.!?]",
            "gendered_pronouns": r"\b(he|him|his|she|her|hers)\b",
            "non_inclusive_terms": r"\b(guys|mankind|blacklist|whitelist|master|slave|crazy|insane|lame)\b",
            "you_addressing": r"\byou\b",
            "second_person_avoid": r"\b(the user|users|one should|people should)\b"
        }
        
        # Microsoft terminology standards
        self.terminology_standards = {
            "AI": {"correct": "AI", "avoid": ["A.I."], "note": "No periods"},
            "email": {"correct": "email", "avoid": ["e-mail"], "note": "One word"},
            "website": {"correct": "website", "avoid": ["web site"], "note": "One word"},
            "sign_in": {"correct": "sign in (verb), sign-in (noun)", "avoid": ["login", "log in"], "note": "Microsoft standard"},
            "setup": {"correct": "set up (verb), setup (noun)", "avoid": ["setup (verb)"], "note": "Context dependent"},
            "wifi": {"correct": "Wi-Fi", "avoid": ["WiFi", "wifi"], "note": "Hyphenated, both caps"}
        }
        
        # Content cache for web requests
        self.content_cache = {}
        self.cache_timeout = 3600  # 1 hour

    async def get_session(self):
        """Get or create aiohttp session."""
        if self.session is None:
            timeout = aiohttp.ClientTimeout(total=10)
            headers = {
                'User-Agent': 'Microsoft-Style-Guide-MCP-Server/2.0'
            }
            self.session = aiohttp.ClientSession(timeout=timeout, headers=headers)
        return self.session
    
    async def close_session(self):
        """Close aiohttp session."""
        if self.session:
            await self.session.close()
            self.session = None

    async def fetch_web_content(self, url: str) -> Dict[str, Any]:
        """Fetch content from Microsoft Style Guide website with caching."""
        # Check cache first
        if url in self.content_cache:
            cached_data = self.content_cache[url]
            # Simple cache timeout check (in production, use proper timestamps)
            return cached_data
        
        try:
            session = await self.get_session()
            async with session.get(url) as response:
                if response.status == 200:
                    content = await response.text()
                    
                    # Extract meaningful content (simplified HTML parsing)
                    title_match = re.search(r'<title>([^<]+)</title>', content)
                    title = title_match.group(1) if title_match else "Microsoft Style Guide"
                    
                    # Extract main content between common markers
                    # Look for article content, remove script/style tags
                    text_content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
                    text_content = re.sub(r'<style[^>]*>.*?</style>', '', text_content, flags=re.DOTALL)
                    text_content = re.sub(r'<[^>]+>', ' ', text_content)
                    text_content = ' '.join(text_content.split())
                    
                    result = {
                        "success": True,
                        "url": url,
                        "title": title,
                        "content": text_content[:2000],  # Limit content size
                        "full_content": text_content,
                        "timestamp": asyncio.get_event_loop().time()
                    }
                    
                    # Cache the result
                    self.content_cache[url] = result
                    return result
                else:
                    return {
                        "success": False,
                        "error": f"HTTP {response.status}",
                        "url": url
                    }
                    
        except Exception as e:
            logger.error(f"Error fetching {url}: {e}")
            return {
                "success": False,
                "error": str(e),
                "url": url
            }

    async def analyze_content(self, text: str, analysis_type: str = "comprehensive") -> Dict[str, Any]:
        """Analyze text content with enhanced web-based guidance."""
        # Start with local pattern analysis (same as offline version)
        issues = []
        suggestions = []
        
        # Basic statistics
        words = text.split()
        sentences = [s for s in re.split(r'[.!?]+', text) if s.strip()]
        word_count = len(words)
        sentence_count = len(sentences)
        avg_words_per_sentence = round(word_count / max(1, sentence_count), 1)
        
        # Pattern-based analysis
        contractions = len(re.findall(self.patterns["contractions"], text, re.IGNORECASE))
        you_usage = len(re.findall(self.patterns["you_addressing"], text, re.IGNORECASE))
        
        if contractions > 0:
            suggestions.append({
                "type": "positive",
                "message": f"Good use of contractions ({contractions} found) - supports warm, natural tone",
                "principle": "warm_and_relaxed"
            })
        else:
            issues.append({
                "type": "voice_tone",
                "severity": "info",
                "message": "Consider using contractions (it's, you're, we'll) for a more natural tone",
                "principle": "warm_and_relaxed"
            })
        
        if you_usage > 0:
            suggestions.append({
                "type": "positive",
                "message": f"Good use of 'you' ({you_usage} instances) - directly engages readers",
                "principle": "ready_to_help"
            })
        
        # Additional pattern checks (grammar, terminology, accessibility)
        if analysis_type in ["comprehensive", "grammar"]:
            passive_matches = list(re.finditer(self.patterns["passive_voice"], text, re.IGNORECASE))
            for match in passive_matches:
                issues.append({
                    "type": "grammar",
                    "severity": "warning",
                    "position": match.start(),
                    "text": match.group(),
                    "message": "Consider using active voice for clarity",
                    "principle": "crisp_and_clear"
                })
        
        if analysis_type in ["comprehensive", "terminology"]:
            for term, standard in self.terminology_standards.items():
                for avoid_term in standard["avoid"]:
                    if avoid_term.lower() in text.lower():
                        issues.append({
                            "type": "terminology",
                            "severity": "warning",
                            "text": avoid_term,
                            "message": f"Use '{standard['correct']}' instead of '{avoid_term}'",
                            "note": standard["note"]
                        })
        
        if analysis_type in ["comprehensive", "accessibility"]:
            non_inclusive_matches = list(re.finditer(self.patterns["non_inclusive_terms"], text, re.IGNORECASE))
            for match in non_inclusive_matches:
                issues.append({
                    "type": "accessibility",
                    "severity": "error",
                    "position": match.start(),
                    "text": match.group(),
                    "message": f"'{match.group()}' may not be inclusive - consider alternatives",
                    "principle": "bias_free_communication"
                })
        
        # Get live guidance for detected issues (web-enhanced feature)
        live_guidance = {}
        if issues:
            try:
                # Get official guidance for the most common issue types
                issue_types = list(set(issue["type"] for issue in issues))
                for issue_type in issue_types[:2]:  # Limit to top 2 to avoid too many requests
                    guidance = await self.get_official_guidance(issue_type)
                    if guidance["guidance"]:
                        live_guidance[issue_type] = guidance["guidance"][0]  # Take first result
            except Exception as e:
                logger.error(f"Error getting live guidance: {e}")
        
        # Generate overall assessment
        total_issues = len(issues)
        if total_issues == 0:
            status = "✅ Excellent"
            assessment = "Content follows Microsoft Style Guide principles well"
        elif total_issues <= 2:
            status = "⚠️ Good"
            assessment = "Minor style improvements suggested"
        else:
            status = "❌ Needs Work"
            assessment = "Multiple style issues detected"
        
        return {
            "status": status,
            "assessment": assessment,
            "statistics": {
                "word_count": word_count,
                "sentence_count": sentence_count,
                "avg_words_per_sentence": avg_words_per_sentence
            },
            "issues": issues,
            "suggestions": suggestions,
            "total_issues": total_issues,
            "analysis_type": analysis_type,
            "style_guide_url": self.style_guide_base_url,
            "live_guidance": live_guidance,
            "web_enabled": True,
            "timestamp": asyncio.get_event_loop().time()
        }

    async def search_style_guide_live(self, query: str) -> Dict[str, Any]:
        """Search Microsoft Style Guide website for live guidance."""
        try:
            search_results = []
            search_terms = query.lower().split()
            
            # Search through core URLs for relevant content
            for section, url in self.core_urls.items():
                content_result = await self.fetch_web_content(url)
                
                if content_result["success"]:
                    content = content_result["full_content"].lower()
                    relevance_score = sum(1 for term in search_terms if term in content)
                    
                    if relevance_score > 0:
                        search_results.append({
                            "section": section,
                            "title": content_result["title"],
                            "url": url,
                            "relevance": "high" if relevance_score >= len(search_terms) // 2 else "medium",
                            "content_preview": content_result["content"],
                            "official": True
                        })
            
            # Sort by relevance
            search_results.sort(key=lambda x: (x["relevance"] == "high", x["section"]), reverse=True)
            
            return {
                "query": query,
                "results": search_results[:5],  # Top 5 results
                "total_found": len(search_results),
                "web_enabled": True,
                "timestamp": asyncio.get_event_loop().time()
            }
            
        except Exception as e:
            logger.error(f"Error searching style guide: {e}")
            return {
                "query": query,
                "error": str(e),
                "results": [],
                "web_enabled": True
            }

    async def get_official_guidance(self, topic: str) -> Dict[str, Any]:
        """Get official guidance from Microsoft Style Guide for a specific topic."""
        try:
            # Map topics to specific URLs
            topic_mappings = {
                "voice": "voice_tone",
                "tone": "voice_tone", 
                "tips": "top_tips",
                "bias": "bias_free",
                "inclusive": "bias_free",
                "writing": "writing_tips",
                "grammar": "writing_tips",
                "words": "word_list",
                "terminology": "word_list"
            }
            
            topic_lower = topic.lower()
            relevant_sections = []
            
            # Find relevant sections
            for key, section in topic_mappings.items():
                if key in topic_lower:
                    relevant_sections.append(section)
            
            # If no specific mapping, search in all sections
            if not relevant_sections:
                relevant_sections = list(self.core_urls.keys())
            
            guidance_results = []
            for section in relevant_sections[:3]:  # Limit to top 3 sections
                if section in self.core_urls:
                    url = self.core_urls[section]
                    content_result = await self.fetch_web_content(url)
                    
                    if content_result["success"]:
                        guidance_results.append({
                            "section": section,
                            "title": content_result["title"],
                            "url": url,
                            "content": content_result["content"],
                            "official": True
                        })
            
            return {
                "topic": topic,
                "guidance": guidance_results,
                "web_enabled": True,
                "timestamp": asyncio.get_event_loop().time()
            }
            
        except Exception as e:
            logger.error(f"Error getting official guidance: {e}")
            return {
                "topic": topic,
                "error": str(e),
                "guidance": [],
                "web_enabled": True
            }

    def get_style_guidelines(self, category: str = "all") -> Dict[str, Any]:
        """Get Microsoft Style Guide guidelines (same as offline but with web URLs)."""
        guidelines = {
            "category": category,
            "base_url": self.style_guide_base_url,
            "principles": {},
            "web_enabled": True
        }
        
        if category in ["voice", "all"]:
            guidelines["principles"]["voice_and_tone"] = {
                "warm_and_relaxed": [
                    "Use contractions (it's, you're, we'll)",
                    "Write like you speak - natural, conversational",
                    "Be friendly and approachable"
                ],
                "crisp_and_clear": [
                    "Be direct and scannable", 
                    "Keep sentences under 25 words",
                    "Use simple, clear language"
                ],
                "ready_to_help": [
                    "Use action-oriented language",
                    "Address readers as 'you'",
                    "Be supportive and encouraging"
                ],
                "official_url": self.core_urls["voice_tone"]
            }
        
        if category in ["grammar", "all"]:
            guidelines["principles"]["grammar"] = {
                "active_voice": "Use active voice for clarity and engagement",
                "sentence_structure": "Keep sentences short and parallel",
                "imperative_mood": "Use for instructions (Click, Choose, Select)",
                "official_url": self.core_urls["writing_tips"]
            }
        
        if category in ["terminology", "all"]:
            guidelines["principles"]["terminology"] = {
                **self.terminology_standards,
                "official_url": self.core_urls["word_list"]
            }
        
        if category in ["accessibility", "all"]:
            guidelines["principles"]["accessibility"] = {
                "inclusive_language": [
                    "Use 'everyone' instead of 'guys'",
                    "Use 'allow list' instead of 'whitelist'",
                    "Use 'primary/secondary' instead of 'master/slave'"
                ],
                "people_first": "Use 'people with disabilities' not 'disabled people'",
                "gender_neutral": "Avoid gendered pronouns in generic references",
                "official_url": self.core_urls["bias_free"]
            }
        
        return guidelines

    async def suggest_improvements(self, text: str, focus_area: str = "all") -> Dict[str, Any]:
        """Generate improvement suggestions with live guidance."""
        analysis = await self.analyze_content(text, "comprehensive")
        improvements = []
        
        for issue in analysis["issues"]:
            if focus_area == "all" or issue["type"] == focus_area:
                improvement = {
                    "issue": issue["message"],
                    "suggestion": self._get_improvement_suggestion(issue),
                    "type": issue["type"],
                    "severity": issue["severity"]
                }
                improvements.append(improvement)
        
        # Add general improvements
        if analysis["statistics"]["avg_words_per_sentence"] > 25:
            improvements.append({
                "issue": "Average sentence length is high",
                "suggestion": "Break long sentences into shorter, clearer ones",
                "type": "grammar",
                "severity": "info"
            })
        
        return {
            "text_preview": text[:100] + "..." if len(text) > 100 else text,
            "total_improvements": len(improvements),
            "improvements": improvements,
            "focus_area": focus_area,
            "style_guide_url": f"{self.style_guide_base_url}/top-10-tips-style-voice",
            "live_guidance": analysis.get("live_guidance", {}),
            "web_enabled": True
        }
    
    def _get_improvement_suggestion(self, issue: Dict[str, Any]) -> str:
        """Generate specific improvement suggestion based on issue type."""
        issue_type = issue["type"]
        
        if issue_type == "voice_tone":
            return "Use more contractions and direct language to sound natural and friendly"
        elif issue_type == "grammar" and "passive" in issue["message"]:
            return f"Change '{issue.get('text', '')}' to active voice"
        elif issue_type == "terminology":
            return f"Replace with Microsoft-approved term as noted"
        elif issue_type == "accessibility":
            return f"Use inclusive alternative for '{issue.get('text', '')}'"
        else:
            return "Follow Microsoft Style Guide recommendations"