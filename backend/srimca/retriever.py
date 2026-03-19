import numpy as np
from .config import knowledge_col, embedding_model

def retrieve_context(question, top_k=5):
    """Retrieve most relevant context using local embeddings."""
    if embedding_model is None:
        return ""

    # Create embedding locally (free)
    q_emb = embedding_model.encode(question)
    
    # Calculate similarity scores
    docs = list(knowledge_col.find())
    scores = []
    
    for d in docs:
        emb = d.get("embedding")
        if not emb:
            continue
        d_emb = np.array(emb)
        score = np.dot(q_emb, d_emb) / (
            np.linalg.norm(q_emb) * np.linalg.norm(d_emb)
        )
        scores.append((score, d["text"]))
    
    # Sort by score and return top_k
    scores.sort(reverse=True)
    top_contexts = [text for _, text in scores[:top_k]]
    
    return "\n".join(top_contexts)
