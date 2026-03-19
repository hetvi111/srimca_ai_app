import os
import glob
import re
from typing import Optional
from pymongo import MongoClient
from openai import OpenAI
from dotenv import load_dotenv
from .config import DATA_DIR, knowledge_col

load_dotenv()

# OpenAI client (optional)
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

# MongoDB (direct connection if needed)
MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net")
DB_NAME = os.getenv("DB_NAME", "srimca_ai")
COLLECTION_KNOWLEDGE = os.getenv("COLLECTION_KNOWLEDGE", "knowledge")


# ---------- LOAD ----------
def load_content() -> str:
    """Load all content from text files in data directory."""
    all_parts = []
    data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    print(f"Loading content from: {data_dir}")
    
    if not os.path.exists(data_dir):
        print(f"Data directory does not exist: {data_dir}")
        return ""
    
    for f in glob.glob(f"{data_dir}/*.txt"):
        print(f"Reading file: {f}")
        with open(f, "r", encoding="utf-8") as file:
            content = file.read()
            print(f"Loaded {len(content)} chars from {os.path.basename(f)}")
            all_parts.append(content)
    
    result = "\n".join(all_parts)
    print(f"Total content loaded: {len(result)} chars")
    return result


# ---------- BUILD ----------
def build_db():
    knowledge_col.delete_many({})
    content = load_content()
    lines = [l.strip() for l in content.split('\n') if l.strip()]
    for i, line in enumerate(lines):
        knowledge_col.insert_one({"text": line, "index": i, "lower": line.lower()})
    print(f"✅ Built with {len(lines)} entries")
    return len(lines)


# ---------- EXACT MATCH (for timetable) ----------
def get_exact_answer(question: str) -> Optional[str]:
    """Get exact answer for specific queries like timetable."""
    q = question.lower()
    content = load_content()
    all_lines = content.split('\n')
    
    # Extract day
    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    found_day = next((d for d in days if d in q), None)
    
    # Extract time
    time_match = re.search(r'(\d{1,2}):(\d{2})\s*[-–to]+\s*(\d{1,2}):(\d{2})', q)
    
    if found_day:
        for i, line in enumerate(all_lines):
            line_l = line.lower().strip()
            
            # Must be a 2nd semester timetable line
            if 'mca 2nd semester' not in line_l:
                continue
            if found_day not in line_l:
                continue
            
            # Collect all timetable lines for this day
            timetable = []
            for j in range(i, len(all_lines)):
                tl = all_lines[j].strip()
                if not tl:
                    continue
                if 'mca' not in tl.lower() or 'semester' not in tl.lower():
                    break
                timetable.append(tl)
            
            if timetable:
                if time_match:
                    # Exact time match
                    start_h = int(time_match.group(1))
                    for tl in timetable:
                        tl_match = re.search(r'(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})', tl)
                        if tl_match:
                            tl_start = int(tl_match.group(1))
                            if tl_start == start_h:
                                return tl.strip()
                else:
                    return f"MCA 2nd Semester {found_day.capitalize()}:\n" + "\n".join(timetable)
    
    return None


# ---------- GPT ANSWER ----------
def get_gpt_answer(question: str) -> str:
    """Get conversational answer from GPT."""
    if not openai_client:
        return None
    
    content = load_content()
    
    system_prompt = """You are SRIMCA AI, a helpful assistant for Shrimad Rajchandra Institute of Management and Computer Application.

Answer the user's question based on the information below. Be friendly, accurate, and conversational.

Information about SRIMCA:
{context}

User question: {question}

Give a clear, helpful answer. If you don't know the answer, say so honestly.""".format(context=content, question=question)
    
    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": question}
            ],
            temperature=0.3,
            max_tokens=300
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"⚠️  OpenAI error: {e}")
        return None


# ---------- FALLBACK (when GPT fails) ----------
def get_fallback_answer(question: str) -> str:
    """Simple keyword-based answer when GPT is unavailable."""
    q = question.lower()
    content = load_content()
    all_lines = content.split('\n')
    
    # Quick patterns - check for key college info
    if 'full name' in q:
        for line in all_lines:
            if 'full name' in line.lower():
                return line.strip()
    
    if 'located' in q or 'where' in q:
        for line in all_lines:
            if 'located' in line.lower():
                return line.strip()
    
    if 'university' in q or 'affiliated' in q:
        for line in all_lines:
            if 'uka tarsadia' in line.lower():
                return line.strip()
            if 'constituent college' in line.lower():
                return line.strip()
    
    if 'vision' in q:
        for line in all_lines:
            if 'vision' in line.lower():
                return line.strip()
    
    if 'mission' in q:
        for line in all_lines:
            if 'mission' in line.lower():
                return line.strip()
    
    if 'courses' in q or 'programme' in q or 'programs' in q or 'offer' in q:
        for line in all_lines:
            if 'offers' in line.lower() or 'programme' in line.lower():
                return line.strip()
    
    if 'computer' in q or 'wifi' in q or 'internet' in q:
        for line in all_lines:
            if 'computer' in line.lower() or 'wi-fi' in line.lower():
                return line.strip()
    
    if 'library' in q or 'book' in q:
        for line in all_lines:
            if 'library' in line.lower():
                return line.strip()
    
    if 'contact' in q or 'email' in q:
        for line in all_lines:
            if 'contact' in line.lower():
                return line.strip()
    
    # Try exact timetable match
    exact = get_exact_answer(question)
    if exact:
        return exact
    
    # Keyword search - find best matching line
    stop = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'we', 'they', 'srimca', 'mca', 'mba', 'my', 'me', 'about', 'tell', 'show', 'get'}
    keywords = [w for w in q.split() if w not in stop and len(w) > 2]
    
    best = None
    best_score = 0
    
    for line in all_lines:
        line = line.strip()
        if not line:
            continue
        score = sum(1 for k in keywords if k in line.lower())
        if score > best_score:
            best_score = score
            best = line
    
    if best and best_score >= 1:
        return best
    
    # Default response with suggestions
    return "I don't have specific information about that. You can ask me about:\n- College name and location\n- Courses offered (MCA, MBA)\n- University affiliation\n- Vision and mission\n- Timetable/schedule\n- Facilities (library, computers, internet)"


# ---------- MAIN ASK ----------
def ask(question: str) -> str:
    """Main answer function."""
    # Try exact answers first (timetable)
    exact = get_exact_answer(question)
    if exact:
        return exact
    
    # Try GPT for conversational answers
    if openai_client:
        gpt_ans = get_gpt_answer(question)
        if gpt_ans:
            return gpt_ans
    
    # Fallback
    return get_fallback_answer(question)


# ---------- MAIN ----------
if __name__ == "__main__":
    import time
    
    print("🤖 SRIMCA AI Ready!")
    print("💡 Type 'exit' to quit\n")
    
    # Build on first run
    if knowledge_col.count_documents({}) == 0:
        build_db()
    else:
        print(f"📚 Using existing knowledge base")
    
    while True:
        q = input("You: ").strip()
        if q.lower() in ["exit", "quit"]:
            print("👋 Goodbye!")
            break
        
        start = time.time()
        ans = ask(q)
        print(f"\nAnswer: {ans}\n")
        print(f"⏱️  {time.time()-start:.2f}s\n")
