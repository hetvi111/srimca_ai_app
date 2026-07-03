from .fallback import get_fallback_answer

def get_gpt_answer(question):
    """
    Lightweight answer generator for Render deployment.
    Uses fallback knowledge base only.
    """
    try:
        answer = get_fallback_answer(question)

        if answer and answer.strip():
            return answer

        return "I could not find information related to your question."
    except Exception as e:
        print(f"GPT/Fallback Error: {e}")
        return "SRIMCA AI is temporarily unavailable."
