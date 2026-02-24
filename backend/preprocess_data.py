"""
SRIMCA Data Preprocessing Script
================================
Location: backend/preprocess_data.py
Purpose: Preprocess data from SRIMCA official website for AI RAG system

This script:
1. Reads raw data from table.txt or data sources
2. Cleans and normalizes the text
3. Creates structured chunks with metadata
4. Saves processed data for the AI system
"""

import os
import re
import json
import glob

# ============ CONFIGURATION ============
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Look for data in multiple locations
DATA_SOURCES = [
    os.path.join(BASE_DIR, "srimca", "data"),
    os.path.join(BASE_DIR, "..", "table.txt"),
    os.path.join(BASE_DIR, "data")
]
OUTPUT_DIR = os.path.join(BASE_DIR, "processed_data")


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
    acronyms = ['MCA', 'MBA', 'BCA', 'AICTE', 'SRIMCA', 'Gujarat', 'Wi-Fi', 'MBps', 'UTU']
    
    result = text
    for acronym in acronyms:
        result = result.replace(acronym, f"_{acronym}_")
    
    result = result.lower()
    
    for acronym in acronyms:
        result = result.replace(f"_{acronym.lower()}_", acronym)
    
    return result


# ============ DATA LOADING ============
def load_raw_data() -> list:
    """Load raw data from all available sources."""
    all_lines = []
    
    # Try to load from table.txt first
    table_path = os.path.join(BASE_DIR, "..", "table.txt")
    if os.path.exists(table_path):
        print(f"Loading from table.txt: {table_path}")
        with open(table_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            # Extract only relevant data lines (skip headers and separators)
            for line in lines:
                line = line.strip()
                # Skip separator lines and headers
                if line and not line.startswith('=') and not line.startswith('+') and not line.startswith('|'):
                    if len(line) > 10:  # Skip very short lines
                        all_lines.append(line)
    
    # Also try to load from srimca data folder
    srimca_data_dir = os.path.join(BASE_DIR, "srimca", "data")
    if os.path.exists(srimca_data_dir):
        print(f"Loading from srimca data folder: {srimca_data_dir}")
        for f in glob.glob(f"{srimca_data_dir}/*.txt"):
            with open(f, 'r', encoding='utf-8') as file:
                for line in file:
                    line = line.strip()
                    if line:
                        all_lines.append(line)
    
    return all_lines


def extract_srimca_info(lines: list) -> list:
    """Extract SRIMCA-specific information from raw lines."""
    extracted = []
    
    # Keywords that indicate relevant SRIMCA data
    keywords = [
        'srimca', 'shrimad', 'rajchandra', 'institute', 'management', 
        'computer', 'application', 'maliba', 'campus', 'gopal', 'vidyanagar',
        'bardoli', 'surat', 'gujarat', 'uka', 'tarsadia', 'university',
        'mca', 'mba', 'bca', 'aicte', 'programme', 'program',
        'semester', 'commenced', 'started', 'year',
        'computer', 'wifi', 'internet', 'library', 'auditorium',
        'mission', 'vision', 'facility'
    ]
    
    for line in lines:
        line_lower = line.lower()
        # Check if line contains relevant keywords
        if any(kw in line_lower for kw in keywords):
            # Clean the line
            cleaned = clean_text(line)
            if cleaned and len(cleaned) > 15:
                extracted.append(cleaned)
    
    return extracted


# ============ CHUNKING ============
def chunk_by_category(lines: list) -> dict:
    """Group lines by category."""
    chunks = {cat: [] for cat in CATEGORIES.keys()}
    
    current_category = "BASIC_INFO"
    
    for line in lines:
        line_lower = line.lower()
        
        # Auto-detect category
        if any(word in line_lower for word in ['mission', 'vision']):
            current_category = "MISSION_VISION"
        elif any(word in line_lower for word in ['semester', 'commenced', 'started', 'year']):
            if any(day in line_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']):
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


def detect_category(text: str) -> str:
    """Detect category for a line of text."""
    text_lower = text.lower()
    
    if 'mission' in text_lower:
        return "MISSION_VISION"
    if 'vision' in text_lower:
        return "MISSION_VISION"
    if any(word in text_lower for word in ['semester', 'commenced', 'started']):
        if any(day in text_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']):
            return "TIMETABLE"
        return "ACADEMIC"
    if any(word in text_lower for word in ['offer', 'programme', 'mca', 'mba', 'bca']):
        return "COURSES"
    if any(word in text_lower for word in ['computer', 'wifi', 'internet', 'library', 'auditorium']):
        return "INFRASTRUCTURE"
    if any(word in text_lower for word in ['located', 'campus', 'surat', 'bardoli']):
        return "CONTACT"
    
    return "BASIC_INFO"


# ============ Q&A GENERATION ============
def generate_qa_pairs(lines: list) -> list:
    """Generate question-answer pairs from the data."""
    qa_pairs = []
    
    # Question templates mapping
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


# ============ MAIN PREPROCESSING ============
def preprocess():
    """Main preprocessing function."""
    print("=" * 60)
    print("SRIMCA DATA PREPROCESSING")
    print("=" * 60)
    
    # Step 1: Load raw data
    print("\n[1/5] Loading raw data...")
    raw_lines = load_raw_data()
    print(f"     {len(raw_lines)} raw lines loaded")
    
    # Step 2: Extract relevant info
    print("\n[2/5] Extracting SRIMCA information...")
    extracted_lines = extract_srimca_info(raw_lines)
    print(f"      Extracted {len(extracted_lines)} relevant lines")
    
    # Step 3: Clean and normalize
    print("\n[3/5] Cleaning and normalizing text...")
    cleaned_lines = [clean_text(line) for line in extracted_lines]
    cleaned_lines = [line for line in cleaned_lines if line]  # Remove empty
    print(f"      Cleaned {len(cleaned_lines)} lines")
    
    # Step 4: Create structured chunks
    print("\n[4/5] Creating structured chunks...")
    category_chunks = chunk_by_category(cleaned_lines)
    
    # Create flat entries with metadata
    flat_entries = []
    for i, line in enumerate(cleaned_lines):
        flat_entries.append({
            "index": i,
            "text": line,
            "text_lower": line.lower(),
            "category": detect_category(line)
        })
    
    # Generate Q&A pairs
    qa_pairs = generate_qa_pairs(cleaned_lines)
    print(f"      Created {len(qa_pairs)} Q&A pairs")
    
    # Step 5: Create knowledge base
    print("\n[5/5] Building knowledge base...")
    knowledge_base = {
        "metadata": {
            "source": "SRIMCA Official Website / table.txt",
            "processed_date": "2025-02-24",
            "total_entries": len(cleaned_lines),
            "categories": list(CATEGORIES.keys())
        },
        "categories": CATEGORIES,
        "by_category": {},
        "flat_entries": flat_entries,
        "qa_pairs": qa_pairs
    }
    
    # Add entries by category
    for cat_key, cat_lines in category_chunks.items():
        if cat_lines:
            knowledge_base["by_category"][CATEGORIES[cat_key]] = cat_lines
    
    # Save processed data
    print("\n[Saving] Creating output directory...")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Save as JSON
    json_path = os.path.join(OUTPUT_DIR, "srimca_knowledge_base.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(knowledge_base, f, indent=2, ensure_ascii=False)
    print(f"      Saved: {json_path}")
    
    # Save as text (for simple retrieval)
    txt_path = os.path.join(OUTPUT_DIR, "srimca_processed.txt")
    with open(txt_path, 'w', encoding='utf-8') as f:
        for entry in flat_entries:
            f.write(entry["text"] + "\n")
    print(f"      Saved: {txt_path}")
    
    # Save Q&A pairs
    qa_path = os.path.join(OUTPUT_DIR, "srimca_qa_pairs.json")
    with open(qa_path, 'w', encoding='utf-8') as f:
        json.dump(qa_pairs, f, indent=2, ensure_ascii=False)
    print(f"      Saved: {qa_path}")
    
    # Print summary
    print("\n" + "=" * 60)
    print("PREPROCESSING SUMMARY")
    print("=" * 60)
    print(f"Total entries: {knowledge_base['metadata']['total_entries']}")
    print(f"Q&A pairs: {len(qa_pairs)}")
    print("\nCategory breakdown:")
    for cat, entries in knowledge_base['by_category'].items():
        print(f"  - {cat}: {len(entries)} entries")
    
    print("\nPreprocessing complete!")
    return knowledge_base


def load_processed_data():
    """Load preprocessed data from output directory."""
    json_path = os.path.join(OUTPUT_DIR, "srimca_knowledge_base.json")
    
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    return None


# ============ ENTRY POINT ============
if __name__ == "__main__":
    preprocess()
