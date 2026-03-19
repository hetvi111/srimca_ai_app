from .exact_match import get_exact_answer
from .gpt_answer import get_gpt_answer
from .fallback import get_fallback_answer
from .build_db import build_db
from .config import knowledge_col


def ask(question):
    """Main answer function with multiple fallbacks."""
    # Step 1: Try exact match (timetable queries)
    exact = get_exact_answer(question)
    if exact:
        return exact
    
    # Step 2: Try GPT with RAG
    try:
        gpt_ans = get_gpt_answer(question)
        if gpt_ans:
            return gpt_ans
    except Exception as e:
        print(f"⚠️  GPT error: {e}")
    
    # Step 3: Fallback to keyword search
    return get_fallback_answer(question)


if __name__ == "__main__":
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
