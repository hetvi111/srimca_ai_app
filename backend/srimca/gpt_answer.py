from .retriever import retrieve_context
from .config import openai_client
from .fallback import get_fallback_answer

def get_gpt_answer(question):
    """Generate answer using GPT with retrieved context."""
    # Try OpenAI if available
    if openai_client:
        try:
            context = retrieve_context(question)
            if not context:
                return None
            
            prompt = f"""You are SRIMCA AI, a helpful assistant for Shrimad Rajchandra Institute.

Answer based on this context:
{context}

Question: {question}

Answer:"""

            response = openai_client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                timeout=20,
                temperature=0.3,
                max_tokens=200
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            print(f"⚠️  OpenAI error: {e}")
    
    # Fallback to direct retrieval (no LLM)
    context = retrieve_context(question)
    if context:
        # Return the most relevant context directly
        return context[:500]
    
    return None
