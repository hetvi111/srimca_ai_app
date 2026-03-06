import glob
import os
import json
from config import DATA_DIR

# Get the processed data directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROCESSED_DATA_DIR = os.path.join(SCRIPT_DIR, "..", "processed_data")


def load_content():
    """Load all text files from data directory."""
    all_text = []
    for f in glob.glob(f"{DATA_DIR}/*.txt"):
        with open(f, "r", encoding="utf-8") as file:
            all_text.append(file.read())
    return "\n".join(all_text)


def load_lines():
    """Load text files as individual lines."""
    all_lines = []
    for f in glob.glob(f"{DATA_DIR}/*.txt"):
        with open(f, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if line:
                    all_lines.append(line)
    return all_lines


def load_processed_data():
    """Load preprocessed data from backend/processed_data directory."""
    json_path = os.path.join(PROCESSED_DATA_DIR, "srimca_knowledge_base.json")
    
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None


def load_qa_pairs():
    """Load preprocessed Q&A pairs."""
    qa_path = os.path.join(PROCESSED_DATA_DIR, "srimca_qa_pairs.json")
    
    if os.path.exists(qa_path):
        with open(qa_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return []


def load_processed_text():
    """Load preprocessed text lines."""
    txt_path = os.path.join(PROCESSED_DATA_DIR, "srimca_processed.txt")
    
    if os.path.exists(txt_path):
        with open(txt_path, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f if line.strip()]
    return []


def get_best_answer(question: str) -> str:
    """Get best answer from preprocessed Q&A pairs based on question keywords."""
    qa_pairs = load_qa_pairs()
    if not qa_pairs:
        return None
    
    question_lower = question.lower()
    
    # Find best matching Q&A pair
    best_match = None
    best_score = 0
    
    for qa in qa_pairs:
        qa_question = qa.get("question", "").lower()
        qa_answer = qa.get("answer", "")
        
        # Count matching words
        question_words = set(question_lower.split())
        qa_words = set(qa_question.split())
        
        # Remove common words
        common_words = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'we', 'they', 'srimca', 'mca', 'mba', 'my', 'me', 'about', 'tell', 'show', 'get'}
        question_words = question_words - common_words
        qa_words = qa_words - common_words
        
        # Calculate score
        score = len(question_words.intersection(qa_words))
        
        if score > best_score:
            best_score = score
            best_match = qa_answer
    
    if best_match and best_score > 0:
        return best_match
    
    return None
