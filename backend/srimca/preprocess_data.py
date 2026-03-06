"""
SRIMCA Data Preprocessing Script
=================================
This script preprocesses raw data from the SRIMCA official website
and prepares it for the AI RAG system.

Preprocessing Steps:
1. Load raw data from source files
2. Clean and normalize text
3. Create structured chunks with metadata
4. Organize by categories (basic info, courses, infrastructure, timetable, etc.)
5. Save processed data for vector database
"""

import os
import re
import json
from datetime import datetime
from typing import List, Dict, Tuple


# ============ CONSTANTS ============
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "processed_data")


# ============ DATA CATEGORIES ============
CATEGORIES = {
    "BASIC_INFO": "Basic Information",
    "COURSES": "Courses & Programs",
    "INFRASTRUCTURE": "Infrastructure & Facilities",
    "ACADEMIC": "Academic Calendar",
    "TIMETABLE": "Class Timetable",
    "MISSION_VISION": "Mission & Vision",
    "CONTACT": "Contact & Location"
}


# ============ CLEANING FUNCTIONS ============
def clean_text(text: str) -> str:
    """Clean and normalize text."""
    if not text:
        return ""
    
    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    
    # Remove special characters but keep necessary punctuation
    text = text.strip()
    
    return text


def normalize_case(text: str, preserve_acronyms: bool = True) -> str:
    """Normalize case while preserving acronyms like MCA, MBA, AICTE, etc."""
    if not preserve_acronyms:
        return text.lower()
    
    # List of acronyms to preserve
    acronyms = ['MCA', 'MBA', 'BCA', 'AICTE', 'SRIMCA', 'Gujarat', 'Wi-Fi', 'MBps']
    
    result = text
    for acronym in acronyms:
        # Replace acronym with placeholder
        result = result.replace(acronym, f"_{acronym}_")
    
    # Convert to lowercase
    result = result.lower()
    
    # Restore acronyms
    for acronym in acronyms:
        result = result.replace(f"_{acronym.lower()}_", acronym)
    
    return result


def extract_key_value(text: str) -> Tuple[str, str]:
    """Extract key-value pairs from text like 'MCA programme started in the year 2002'."""
    patterns = [
        r'(.+?)\s+started\s+in\s+the\s+year\s+(\d{4})',
        r'(.+?)\s+commenced\s+from\s+(.+)',
        r'(.+?)\s+has\s+(.+)',
        r'(.+?)\s+is\s+(.+)',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1).strip(), match.group(2).strip()
    
    return text, ""


# ============ CHUNKING FUNCTIONS ============
def chunk_by_category(lines: List[str]) -> Dict[str, List[str]]:
    """Group lines by category."""
    chunks = {cat: [] for cat in CATEGORIES.keys()}
    
    current_category = "BASIC_INFO"
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        line_lower = line.lower()
        
        # Auto-detect category
        if any(word in line_lower for word in ['mission', 'vision']):
            current_category = "MISSION_VISION"
        elif any(word in line_lower for word in ['semester', 'commenced', 'started']):
            if 'timetable' in line_lower or any(day in line_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']):
                current_category = "TIMETABLE"
            else:
                current_category = "ACADEMIC"
        elif any(word in line_lower for word in ['offer', 'programme', 'program', 'mca', 'mba', 'bca']):
            current_category = "COURSES"
        elif any(word in line_lower for word in ['computer', 'wifi', 'internet', 'library', 'auditorium', 'classroom', 'book', 'journal']):
            current_category = "INFRASTRUCTURE"
        elif any(word in line_lower for word in ['located', 'location', 'campus', 'surat', 'bardoli']):
            current_category = "CONTACT"
        
        chunks[current_category].append(line)
    
    return chunks


def create_semantic_chunks(lines: List[str]) -> List[Dict]:
    """Create semantic chunks with metadata."""
    chunks = []
    chunk_id = 0
    
    # Group related lines together
    current_chunk = {
        "id": chunk_id,
        "category": "",
        "topic": "",
        "content": [],
        "keywords": []
    }
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Detect topic changes
        topic_keywords = {
            "location": ["located", "address", "campus"],
            "courses": ["mca", "mba", "bca", "programme", "program"],
            "history": ["started", "commenced", "year"],
            "facilities": ["computer", "wifi", "internet", "library", "auditorium"],
            "timetable": ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday"],
            "mission": ["mission"],
            "vision": ["vision"]
        }
        
        detected_topic = None
        for topic, keywords in topic_keywords.items():
            if any(kw in line.lower() for kw in keywords):
                detected_topic = topic
                break
        
        # If topic changed and we have content, save current chunk
        if current_chunk["topic"] and detected_topic != current_chunk["topic"] and current_chunk["content"]:
            current_chunk["content"] = " | ".join(current_chunk["content"])
            chunks.append(current_chunk)
            chunk_id += 1
            current_chunk = {
                "id": chunk_id,
                "category": "",
                "topic": detected_topic or "",
                "content": [],
                "keywords": []
            }
        
        # Add line to current chunk
        current_chunk["topic"] = detected_topic or current_chunk["topic"]
        current_chunk["content"].append(line)
        
        # Extract keywords
        words = re.findall(r'\b[a-zA-Z]{3,}\b', line.lower())
        current_chunk["keywords"].extend(words)
    
    # Don't forget the last chunk
    if current_chunk["content"]:
        current_chunk["content"] = " | ".join(current_chunk["content"])
        chunks.append(current_chunk)
    
    # Remove duplicates from keywords
    for chunk in chunks:
        chunk["keywords"] = list(set(chunk["keywords"]))
    
    return chunks


# ============ MAIN PREPROCESSING ============
def preprocess_srimca_data() -> Dict:
    """Main preprocessing function."""
    print("🚀 Starting SRIMCA Data Preprocessing...")
    
    # Load raw data
    print("\n📂 Loading raw data...")
    raw_lines = []
    
    if not os.path.exists(DATA_DIR):
        print(f"❌ Data directory not found: {DATA_DIR}")
        return {"error": "Data directory not found"}
    
    for filename in os.listdir(DATA_DIR):
        if filename.endswith('.txt'):
            filepath = os.path.join(DATA_DIR, filename)
            print(f"   Reading: {filename}")
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                raw_lines.extend(lines)
    
    print(f"   Total raw lines: {len(raw_lines)}")
    
    # Clean lines
    print("\n🧹 Cleaning text...")
    cleaned_lines = []
    for line in raw_lines:
        cleaned = clean_text(line)
        if cleaned:
            cleaned_lines.append(cleaned)
    
    print(f"   Cleaned lines: {len(cleaned_lines)}")
    
    # Create chunks
    print("\n📦 Creating semantic chunks...")
    category_chunks = chunk_by_category(cleaned_lines)
    semantic_chunks = create_semantic_chunks(cleaned_lines)
    
    print(f"   Category chunks created: {len(category_chunks)}")
    print(f"   Semantic chunks created: {len(semantic_chunks)}")
    
    # Create structured knowledge base
    print("\n🏗️ Building knowledge base...")
    knowledge_base = {
        "metadata": {
            "source": "SRIMCA Official Website",
            "processed_date": datetime.now().isoformat(),
            "total_entries": len(cleaned_lines)
        },
        "categories": CATEGORIES,
        "by_category": {},
        "semantic_chunks": semantic_chunks,
        "flat_entries": []
    }
    
    # Add entries by category
    for cat_key, cat_lines in category_chunks.items():
        if cat_lines:
            knowledge_base["by_category"][CATEGORIES[cat_key]] = cat_lines
    
    # Create flat entries (for simple keyword matching)
    for i, line in enumerate(cleaned_lines):
        entry = {
            "index": i,
            "text": line,
            "text_lower": line.lower(),
            "category": detect_category(line)
        }
        knowledge_base["flat_entries"].append(entry)
    
    # Create enhanced question-answer pairs
    print("\n❓ Generating Q&A pairs...")
    qa_pairs = generate_qa_pairs(cleaned_lines)
    knowledge_base["qa_pairs"] = qa_pairs
    
    print(f"   Generated {len(qa_pairs)} Q&A pairs")
    
    return knowledge_base


def detect_category(text: str) -> str:
    """Detect category for a line of text."""
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['mission']):
        return "MISSION_VISION"
    if any(word in text_lower for word in ['vision']):
        return "MISSION_VISION"
    if any(word in text_lower for word in ['semester', 'commenced', 'started', 'year']):
        if any(day in text_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']):
            return "TIMETABLE"
        return "ACADEMIC"
    if any(word in text_lower for word in ['offer', 'programme', 'mca', 'mba', 'bca']):
        return "COURSES"
    if any(word in text_lower for word in ['computer', 'wifi', 'internet', 'library', 'auditorium', 'classroom']):
        return "INFRASTRUCTURE"
    if any(word in text_lower for word in ['located', 'campus', 'surat', 'bardoli']):
        return "CONTACT"
    
    return "BASIC_INFO"


def generate_qa_pairs(lines: List[str]) -> List[Dict]:
    """Generate question-answer pairs from the data."""
    qa_pairs = []
    
    # Common question templates
    templates = {
        "full name": ["What is the full name of SRIMCA?", "What does SRIMCA stand for?"],
        "located": ["Where is SRIMCA located?", "What is the address of SRIMCA?"],
        "university": ["Which university is SRIMCA affiliated with?", "Is SRIMCA affiliated to a university?"],
        "offers": ["What courses does SRIMCA offer?", "What programs are available at SRIMCA?"],
        "mission": ["What is the mission of SRIMCA?", "What is SRIMCA's mission statement?"],
        "vision": ["What is the vision of SRIMCA?", "What is SRIMCA's vision statement?"],
        "computer": ["How many computers does SRIMCA have?", "What are the computer facilities at SRIMCA?"],
        "internet": ["What is the internet speed at SRIMCA?", "Is there Wi-Fi at SRIMCA?"],
        "library": ["What facilities does the library have?", "Does SRIMCA have a library?"],
        "started": ["When did MCA/MBA programme start?", "When was SRIMCA established?"],
    }
    
    for line in lines:
        line_lower = line.lower()
        
        for key, questions in templates.items():
            if key in line_lower:
                for question in questions:
                    qa_pairs.append({
                        "question": question,
                        "answer": line,
                        "keywords": [key]
                    })
                break
    
    return qa_pairs


def save_processed_data(knowledge_base: Dict):
    """Save processed data to output directory."""
    print("\n💾 Saving processed data...")
    
    # Create output directory if not exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Save as JSON
    json_path = os.path.join(OUTPUT_DIR, "srimca_knowledge_base.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(knowledge_base, f, indent=2, ensure_ascii=False)
    print(f"   Saved JSON: {json_path}")
    
    # Save flat entries as text (for simple retrieval)
    txt_path = os.path.join(OUTPUT_DIR, "srimca_processed.txt")
    with open(txt_path, 'w', encoding='utf-8') as f:
        for entry in knowledge_base["flat_entries"]:
            f.write(entry["text"] + "\n")
    print(f"   Saved TXT: {txt_path}")
    
    # Save Q&A pairs
    qa_path = os.path.join(OUTPUT_DIR, "srimca_qa_pairs.json")
    with open(qa_path, 'w', encoding='utf-8') as f:
        json.dump(knowledge_base["qa_pairs"], f, indent=2, ensure_ascii=False)
    print(f"   Saved Q&A: {qa_path}")
    
    print("\n✅ Preprocessing complete!")


def load_processed_data() -> Dict:
    """Load processed data from output directory."""
    json_path = os.path.join(OUTPUT_DIR, "srimca_knowledge_base.json")
    
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    return None


# ============ MAIN ============
if __name__ == "__main__":
    # Run preprocessing
    kb = preprocess_srimca_data()
    
    if "error" not in kb:
        save_processed_data(kb)
        
        # Show summary
        print("\n" + "="*50)
        print("📊 PREPROCESSING SUMMARY")
        print("="*50)
        print(f"Total entries: {kb['metadata']['total_entries']}")
        print(f"Categories: {len(kb['categories'])}")
        print(f"Semantic chunks: {len(kb['semantic_chunks'])}")
        print(f"Q&A pairs: {len(kb['qa_pairs'])}")
        print("\nCategory breakdown:")
        for cat, entries in kb['by_category'].items():
            print(f"  - {cat}: {len(entries)} entries")
    else:
        print(f"❌ Error: {kb['error']}")
