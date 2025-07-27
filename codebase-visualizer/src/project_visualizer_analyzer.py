#!/usr/bin/env python3
"""
Comprehensive Project Structure Analyzer for D3.js Visualization
Analyzes the entire PRPs-agentic-eng project to create a multi-level knowledge graph
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Any, Set, Optional
from dataclasses import dataclass
import mimetypes
import hashlib

@dataclass
class FileNode:
    """Represents a file node with metadata and relationships"""
    name: str
    path: str
    type: str
    category: str
    size: int
    lines: int
    language: str
    content_summary: str
    key_concepts: List[str]
    dependencies: List[str]
    relationships: List[str]
    prp_connections: List[str]

class ProjectAnalyzer:
    """Analyzes the entire project structure for visualization"""
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.project_data = {
            "name": "PRPs-agentic-eng",
            "description": "AI-Assisted iOS Voice Control App Development Ecosystem",
            "nodes": [],
            "links": [],
            "categories": {},
            "hierarchy": {},
            "metadata": {
                "analysis_timestamp": "",
                "total_files": 0,
                "total_lines": 0,
                "languages": {},
                "prp_methodology": {}
            }
        }
        
        # Define file categories and colors
        self.categories = {
            "ios_swift": {"name": "iOS Swift Code", "color": "#007AFF", "symbol": "📱"},
            "documentation": {"name": "Documentation", "color": "#34C759", "symbol": "📚"},
            "ai_claude": {"name": "AI/Claude Files", "color": "#AF52DE", "symbol": "🤖"},
            "configuration": {"name": "Configuration", "color": "#FF9500", "symbol": "⚙️"},
            "tests": {"name": "Tests & Validation", "color": "#FF3B30", "symbol": "🧪"},
            "tools": {"name": "Tools & Utilities", "color": "#FF9F0A", "symbol": "🛠️"},
            "prp_methodology": {"name": "PRP Methodology", "color": "#5856D6", "symbol": "📋"},
            "thinking": {"name": "Analysis & Thinking", "color": "#32D74B", "symbol": "💭"},
            "network": {"name": "Network & Communication", "color": "#64D2FF", "symbol": "🌐"}
        }
        
        # File patterns for categorization
        self.file_patterns = {
            "ios_swift": [r"\.swift$", r"VoiceControlApp/.*"],
            "documentation": [r"\.md$", r"README", r"docs/.*", r"ONBOARDING", r"QUICKSTART"],
            "ai_claude": [r"CLAUDE\.md$", r"claude_md_files/.*", r".*claude.*\.md$"],
            "configuration": [r"\.plist$", r"\.json$", r"\.entitlements$", r"Package\.resolved", r"Info\.plist"],
            "tests": [r"Test.*\.swift$", r".*Tests/.*", r"test_.*\.py$", r".*test.*\.swift$"],
            "tools": [r"mobile-mcp-ios/.*", r"ComputerReceiver/.*", r"voice-command-tester/.*"],
            "prp_methodology": [r"PRPs/.*\.md$", r"prp_.*\.py$"],
            "thinking": [r"thinking/.*"],
            "network": [r".*Network.*", r".*RCP.*", r"receiver.*\.py$"]
        }
        
        # Skip these directories/files
        self.skip_patterns = [
            r"\.git/",
            r"node_modules/",
            r"Pods/",
            r"\.xcodeproj/",
            r"build/",
            r"\.DS_Store",
            r"\.log$",
            r"\.xcuserstate$"
        ]

    def should_skip_file(self, file_path: str) -> bool:
        """Check if file should be skipped based on patterns"""
        for pattern in self.skip_patterns:
            if re.search(pattern, file_path):
                return True
        return False

    def categorize_file(self, file_path: str) -> str:
        """Categorize file based on path and content"""
        file_path_str = str(file_path)
        
        for category, patterns in self.file_patterns.items():
            for pattern in patterns:
                if re.search(pattern, file_path_str, re.IGNORECASE):
                    return category
        
        return "tools"  # Default category

    def extract_file_language(self, file_path: Path) -> str:
        """Extract programming language from file extension"""
        suffix = file_path.suffix.lower()
        language_map = {
            ".swift": "Swift",
            ".py": "Python",
            ".js": "JavaScript",
            ".ts": "TypeScript",
            ".md": "Markdown",
            ".json": "JSON",
            ".plist": "XML/Plist",
            ".html": "HTML",
            ".css": "CSS",
            ".yml": "YAML",
            ".yaml": "YAML"
        }
        return language_map.get(suffix, "Unknown")

    def analyze_swift_file(self, content: str) -> Dict[str, Any]:
        """Analyze Swift file for classes, protocols, functions"""
        analysis = {
            "classes": [],
            "protocols": [],
            "functions": [],
            "imports": [],
            "key_concepts": []
        }
        
        # Find imports
        imports = re.findall(r'import\s+(\w+)', content)
        analysis["imports"] = list(set(imports))
        
        # Find classes
        classes = re.findall(r'class\s+(\w+)', content)
        analysis["classes"] = list(set(classes))
        
        # Find protocols
        protocols = re.findall(r'protocol\s+(\w+)', content)
        analysis["protocols"] = list(set(protocols))
        
        # Find functions
        functions = re.findall(r'func\s+(\w+)', content)
        analysis["functions"] = list(set(functions))
        
        # Extract key concepts
        concepts = []
        if "Authentication" in content:
            concepts.append("Authentication")
        if "Speech" in content or "Voice" in content:
            concepts.append("Speech Recognition")
        if "Firebase" in content:
            concepts.append("Firebase")
        if "Google" in content:
            concepts.append("Google Services")
        if "RCP" in content or "Yamaha" in content:
            concepts.append("Audio Mixer Control")
        if "Subscription" in content:
            concepts.append("In-App Purchases")
        
        analysis["key_concepts"] = concepts
        return analysis

    def analyze_markdown_file(self, content: str, file_path: str) -> Dict[str, Any]:
        """Analyze markdown file for structure and PRP connections"""
        analysis = {
            "headings": [],
            "prp_type": None,
            "implementation_status": None,
            "related_files": [],
            "key_concepts": []
        }
        
        # Extract headings
        headings = re.findall(r'^#+\s+(.+)$', content, re.MULTILINE)
        analysis["headings"] = headings
        
        # Determine if it's a PRP
        if "PRPs/" in file_path:
            analysis["prp_type"] = "Product Requirement Prompt"
            if "task-" in file_path:
                analysis["prp_type"] = "Task PRP"
            elif "Personal/" in file_path:
                analysis["prp_type"] = "Personal PRP"
        
        # Extract key concepts
        concepts = []
        if "authentication" in content.lower():
            concepts.append("Authentication")
        if "speech" in content.lower() or "voice" in content.lower():
            concepts.append("Speech Recognition")
        if "firebase" in content.lower():
            concepts.append("Firebase")
        if "ui" in content.lower() or "interface" in content.lower():
            concepts.append("User Interface")
        if "subscription" in content.lower():
            concepts.append("Subscriptions")
        if "claude" in content.lower() or "ai" in content.lower():
            concepts.append("AI Development")
        
        analysis["key_concepts"] = concepts
        return analysis

    def analyze_python_file(self, content: str) -> Dict[str, Any]:
        """Analyze Python file for classes, functions, imports"""
        analysis = {
            "classes": [],
            "functions": [],
            "imports": [],
            "key_concepts": []
        }
        
        # Find imports
        imports = re.findall(r'(?:from\s+\w+\s+)?import\s+(\w+)', content)
        analysis["imports"] = list(set(imports))
        
        # Find classes
        classes = re.findall(r'class\s+(\w+)', content)
        analysis["classes"] = list(set(classes))
        
        # Find functions
        functions = re.findall(r'def\s+(\w+)', content)
        analysis["functions"] = list(set(functions))
        
        # Extract key concepts
        concepts = []
        if "receiver" in content.lower() or "network" in content.lower():
            concepts.append("Network Communication")
        if "voice" in content.lower() or "command" in content.lower():
            concepts.append("Voice Commands")
        if "gui" in content.lower() or "ui" in content.lower():
            concepts.append("User Interface")
        if "test" in content.lower():
            concepts.append("Testing")
        
        analysis["key_concepts"] = concepts
        return analysis

    def read_file_safely(self, file_path: Path) -> Optional[str]:
        """Safely read file content with encoding detection"""
        try:
            # Try UTF-8 first
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except UnicodeDecodeError:
            try:
                # Try with latin-1 encoding
                with open(file_path, 'r', encoding='latin-1') as f:
                    return f.read()
            except Exception:
                return None
        except Exception:
            return None

    def analyze_file(self, file_path: Path) -> Optional[FileNode]:
        """Analyze individual file and extract metadata"""
        if self.should_skip_file(str(file_path)):
            return None
        
        try:
            if not file_path.is_file():
                return None
            
            # Get file stats
            stat = file_path.stat()
            content = self.read_file_safely(file_path)
            
            if content is None:
                return None
            
            lines = len(content.splitlines()) if content else 0
            category = self.categorize_file(str(file_path))
            language = self.extract_file_language(file_path)
            
            # Analyze content based on file type
            analysis_result = {}
            if language == "Swift":
                analysis_result = self.analyze_swift_file(content)
            elif language == "Markdown":
                analysis_result = self.analyze_markdown_file(content, str(file_path))
            elif language == "Python":
                analysis_result = self.analyze_python_file(content)
            
            # Create content summary
            summary = ""
            if analysis_result.get("classes"):
                summary += f"Classes: {', '.join(analysis_result['classes'][:3])}. "
            if analysis_result.get("functions"):
                summary += f"Functions: {len(analysis_result['functions'])}. "
            if analysis_result.get("headings"):
                summary += f"Sections: {', '.join(analysis_result['headings'][:2])}..."
            
            if not summary and content:
                # Generate summary from first few lines
                first_lines = content.split('\n')[:3]
                summary = ' '.join(first_lines).strip()[:200] + "..."
            
            return FileNode(
                name=file_path.name,
                path=str(file_path.relative_to(self.root_path)),
                type="file",
                category=category,
                size=stat.st_size,
                lines=lines,
                language=language,
                content_summary=summary,
                key_concepts=analysis_result.get("key_concepts", []),
                dependencies=analysis_result.get("imports", []),
                relationships=[],
                prp_connections=[]
            )
            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            return None

    def build_hierarchy(self) -> Dict[str, Any]:
        """Build hierarchical structure of the project"""
        hierarchy = {
            "name": "PRPs-agentic-eng",
            "type": "project",
            "children": []
        }
        
        # Main project sections
        sections = {
            "ios_app": {
                "name": "iOS App (VoiceControlApp)",
                "category": "ios_swift",
                "children": []
            },
            "prp_methodology": {
                "name": "PRP Methodology",
                "category": "prp_methodology", 
                "children": []
            },
            "documentation": {
                "name": "Documentation",
                "category": "documentation",
                "children": []
            },
            "ai_tools": {
                "name": "AI Tools & Agents",
                "category": "ai_claude",
                "children": []
            },
            "development_tools": {
                "name": "Development Tools",
                "category": "tools",
                "children": []
            },
            "analysis": {
                "name": "Analysis & Thinking",
                "category": "thinking",
                "children": []
            }
        }
        
        for node in self.project_data["nodes"]:
            path_parts = Path(node["path"]).parts
            
            # Categorize into main sections
            if path_parts[0] == "VoiceControlApp":
                sections["ios_app"]["children"].append(node)
            elif path_parts[0] == "PRPs":
                sections["prp_methodology"]["children"].append(node)
            elif path_parts[0] == "docs" or node["name"].endswith(".md"):
                sections["documentation"]["children"].append(node)
            elif path_parts[0] == "claude_md_files" or "claude" in node["name"].lower():
                sections["ai_tools"]["children"].append(node)
            elif path_parts[0] in ["mobile-mcp-ios", "ComputerReceiver", "voice-command-tester"]:
                sections["development_tools"]["children"].append(node)
            elif path_parts[0] == "thinking":
                sections["analysis"]["children"].append(node)
            else:
                sections["development_tools"]["children"].append(node)
        
        hierarchy["children"] = list(sections.values())
        return hierarchy

    def find_relationships(self):
        """Find relationships between files based on imports, references, etc."""
        relationships = []
        
        for i, node1 in enumerate(self.project_data["nodes"]):
            for j, node2 in enumerate(self.project_data["nodes"]):
                if i != j:
                    # Check for imports/dependencies
                    if any(dep in node2["name"] for dep in node1.get("dependencies", [])):
                        relationships.append({
                            "source": node1["path"],
                            "target": node2["path"],
                            "type": "imports",
                            "strength": 1
                        })
                    
                    # Check for PRP to implementation relationships
                    if (node1.get("category") == "prp_methodology" and 
                        node2.get("category") == "ios_swift" and
                        any(concept in node2.get("key_concepts", []) for concept in node1.get("key_concepts", []))):
                        relationships.append({
                            "source": node1["path"],
                            "target": node2["path"],
                            "type": "prp_implementation",
                            "strength": 2
                        })
        
        self.project_data["links"] = relationships

    def analyze_project(self) -> Dict[str, Any]:
        """Main analysis method"""
        print("Starting comprehensive project analysis...")
        
        total_files = 0
        total_lines = 0
        languages = {}
        
        # Walk through all files
        for root, dirs, files in os.walk(self.root_path):
            # Skip certain directories
            dirs[:] = [d for d in dirs if not any(re.search(pattern, d) for pattern in self.skip_patterns)]
            
            for file in files:
                file_path = Path(root) / file
                
                if self.should_skip_file(str(file_path)):
                    continue
                
                file_node = self.analyze_file(file_path)
                if file_node:
                    node_dict = {
                        "name": file_node.name,
                        "path": file_node.path,
                        "type": file_node.type,
                        "category": file_node.category,
                        "size": file_node.size,
                        "lines": file_node.lines,
                        "language": file_node.language,
                        "content_summary": file_node.content_summary,
                        "key_concepts": file_node.key_concepts,
                        "dependencies": file_node.dependencies,
                        "id": hashlib.md5(file_node.path.encode()).hexdigest()[:8]
                    }
                    
                    self.project_data["nodes"].append(node_dict)
                    total_files += 1
                    total_lines += file_node.lines
                    
                    # Track languages
                    lang = file_node.language
                    languages[lang] = languages.get(lang, 0) + 1
        
        print(f"Analyzed {total_files} files with {total_lines} total lines")
        
        # Build relationships
        self.find_relationships()
        
        # Build hierarchy
        hierarchy = self.build_hierarchy()
        
        # Update metadata
        self.project_data.update({
            "categories": self.categories,
            "hierarchy": hierarchy,
            "metadata": {
                "analysis_timestamp": "2025-01-25T12:00:00Z",
                "total_files": total_files,
                "total_lines": total_lines,
                "languages": languages,
                "prp_methodology": {
                    "description": "AI-assisted development using Product Requirement Prompts",
                    "workflow": "PRP → Analysis → Implementation → Validation",
                    "tools": ["Claude Code", "Firebase", "AssemblyAI", "Yamaha RCP"]
                }
            }
        })
        
        return self.project_data

    def save_analysis(self, output_path: str):
        """Save analysis results to JSON file"""
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(self.project_data, f, indent=2, ensure_ascii=False)
        print(f"Analysis saved to {output_path}")

def main():
    """Main execution function"""
    root_path = "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"
    output_path = os.path.join(root_path, "codebase-visualizer", "data", "project_visualization_data.json")
    
    analyzer = ProjectAnalyzer(root_path)
    project_data = analyzer.analyze_project()
    analyzer.save_analysis(output_path)
    
    print("\n=== Analysis Summary ===")
    print(f"Total files: {project_data['metadata']['total_files']}")
    print(f"Total lines: {project_data['metadata']['total_lines']}")
    print(f"Languages: {list(project_data['metadata']['languages'].keys())}")
    print(f"Categories: {len(project_data['categories'])}")
    print(f"Relationships: {len(project_data['links'])}")
    
    return project_data

if __name__ == "__main__":
    main()