import re
from .exact_match import get_exact_answer
from .gpt_answer import get_gpt_answer
from .fallback import get_fallback_answer
from .build_db import build_db
from .config import get_knowledge_collection


def get_approved_knowledge_answer(question: str):
    """
    Search MongoDB knowledge base for admin-approved answers.
    Supports title, tags, question, category, and text matching.
    """
    try:
        col = get_knowledge_collection()
        if col is None:
            return None
        
        q_clean = question.strip().lower()
        stop_words = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'tell', 'me', 'please', 'give', 'detail', 'details', 'about'}
        words = [w for w in re.sub(r'[^\w\s]', ' ', q_clean).split() if w not in stop_words and len(w) > 2]
        
        # 1. Try exact or regex match on title, question, or tags
        doc = col.find_one({
            'status': {'$ne': 'pending'},
            '$or': [
                {'title': {'$regex': f"^{re.escape(q_clean)}$", '$options': 'i'}},
                {'question': {'$regex': f"^{re.escape(q_clean)}$", '$options': 'i'}},
                {'tags': q_clean}
            ]
        })
        if doc:
            return doc.get('text') or doc.get('answer')
        
        # 2. Try keyword match across approved docs
        if words:
            regex_pattern = '|'.join(re.escape(w) for w in words)
            cursor = col.find({
                'status': {'$ne': 'pending'},
                '$or': [
                    {'title': {'$regex': regex_pattern, '$options': 'i'}},
                    {'tags': {'$in': words}},
                    {'category': {'$in': words}},
                    {'text': {'$regex': regex_pattern, '$options': 'i'}}
                ]
            }).limit(15)
            
            best_doc = None
            best_score = 0
            for d in cursor:
                score = 0
                title_lower = (d.get('title') or d.get('question') or '').lower()
                text_lower = (d.get('text') or d.get('answer') or '').lower()
                tags = [str(t).lower() for t in d.get('tags', [])]
                for w in words:
                    if w in title_lower:
                        score += 3
                    if w in tags:
                        score += 3
                    if w in text_lower:
                        score += 1
                if score > best_score:
                    best_score = score
                    best_doc = d
            
            if best_doc and best_score >= 2:
                return best_doc.get('text') or best_doc.get('answer')
                
    except Exception as e:
        print(f"[Knowledge Search Error]: {e}")
    return None


def ask(question):
    """Main answer function with multiple fallbacks."""
    # Step 1: Check MongoDB Knowledge Base for approved official info
    kb_ans = get_approved_knowledge_answer(question)
    if kb_ans:
        return kb_ans

    # Step 2: Try exact match (timetable queries)
    exact = get_exact_answer(question)
    if exact:
        return exact
    
    # Step 3: Try GPT with RAG
    try:
        gpt_ans = get_gpt_answer(question)
        if gpt_ans:
            return gpt_ans
    except Exception as e:
        print(f"[GPT Error]: {e}")
    
    # Step 4: Fallback to keyword search
    return get_fallback_answer(question)


if __name__ == "__main__":
    knowledge_col = get_knowledge_collection()
    # Build database if empty
    if knowledge_col.count_documents({}) == 0:
        print("📦 Building knowledge database...")
        build_db()
    
    print("\n🤖 SRIMCA AI Ready (RAG Enabled)")
    print("💡 Type 'exit' to quit\n")
    
    while True:
        q = input("You: ").strip()
        if q.lower() in ["exit", "quit"]:
            print("👋 Goodbye!")
            break
        print(f"\nAnswer: {ask(q)}\n")
