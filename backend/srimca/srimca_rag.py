import os
import glob
import re
from typing import Optional
from pymongo import MongoClient
from openai import OpenAI
from dotenv import load_dotenv
from config import DATA_DIR, knowledge_col

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
    all_parts = []
    for f in glob.glob(f"{DATA_DIR}/*.txt"):
        with open(f, "r", encoding="utf-8") as file:
            all_parts.append(file.read())
    return "\n".join(all_parts)


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
    
    # Quick patterns
    if 'full name' in q:
        for line in all_lines:
            if 'full name' in line.lower():
                return line.strip()
    
    if 'located' in q or 'where' in q:
        for line in all_lines:
            if 'located' in line.lower():
                return line.strip()
    
    if 'university' in q:
        for line in all_lines:
            if 'uka tarsadia' in line.lower():
                return line.strip()
    
    if 'vision' in q:
        for line in all_lines:
            if 'vision' in line.lower():
                return line.strip()
    
    if 'mission' in q:
        for line in all_lines:
            if 'mission' in line.lower():
                return line.strip()
    
    # Try exact timetable match
    exact = get_exact_answer(question)
    if exact:
        return exact
    
    # Keyword search
    stop = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'we', 'they', 'srimca', 'mca', 'mba'}
    keywords = [w for w in q.split() if w not in stop and len(w) > 2]
    
    best = None
    best_score = 0
    
    for line in all_lines:
        score = sum(1 for k in keywords if k in line.lower())
        if score > best_score:
            best_score = score
            best = line
    
    if best and best_score >= 1:
        return best.strip()
    
    return "I don't have that information."


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
