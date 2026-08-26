from .fallback import get_fallback_answer
import os

try:
    from openai import OpenAI
    api_key = os.getenv('OPENAI_API_KEY')
    openai_client = OpenAI(api_key=api_key) if api_key else None
except Exception:
    openai_client = None


def get_gpt_answer(question):
    """Answer generator using OpenAI GPT if configured, or fallback engine."""
    if openai_client:
        try:
            prompt = f"You are SRIMCA AI Assistant. Question: {question}"
            response = openai_client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                timeout=8,
                temperature=0.3,
                max_tokens=250
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            print(f"⚠️ OpenAI error: {e}")

    try:
        answer = get_fallback_answer(question)
        if answer and answer.strip():
            return answer
    except Exception as e:
        print(f"Fallback Error: {e}")

    return "SRIMCA AI is currently unable to answer your query."
