import math
from .config import get_knowledge_collection, get_embedding_model

def retrieve_context(question, top_k=5):
    """Retrieve most relevant context using local embeddings."""
    embedding_model = get_embedding_model()
    if embedding_model is None:
        return ""

    # Create embedding locally (free)
    q_emb = embedding_model.encode(question)
    
    # Calculate similarity scores
    knowledge_col = get_knowledge_collection()
    docs = list(knowledge_col.find())
    scores = []
    
    for d in docs:
        emb = d.get("embedding")
        if not emb:
            continue

        # Use pure-Python cosine similarity to avoid hard numpy dependency.
        if len(q_emb) != len(emb):
            continue
        dot = sum(float(a) * float(b) for a, b in zip(q_emb, emb))
        q_norm = math.sqrt(sum(float(a) * float(a) for a in q_emb))
        d_norm = math.sqrt(sum(float(b) * float(b) for b in emb))
        if q_norm == 0.0 or d_norm == 0.0:
            continue
        score = dot / (q_norm * d_norm)
        scores.append((score, d["text"]))
    
    # Sort by score and return top_k
    scores.sort(reverse=True)
    top_contexts = [text for _, text in scores[:top_k]]
    
    return "\n".join(top_contexts)
