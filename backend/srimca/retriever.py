import math
from .config import get_knowledge_collection, get_embedding_model


def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors."""
    if len(vec1) != len(vec2):
        return 0.0

    dot = sum(float(a) * float(b) for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(float(a) * float(a) for a in vec1))
    norm2 = math.sqrt(sum(float(b) * float(b) for b in vec2))

    if norm1 == 0.0 or norm2 == 0.0:
        return 0.0

    return dot / (norm1 * norm2)


def retrieve_context(question, top_k=1):
    """
    Retrieve most relevant SRIMCA context using embeddings.
    Optimized for Render deployment.
    """
    try:
        embedding_model = get_embedding_model()

        if embedding_model is None:
            return ""

        # Create embedding for user question
        q_emb = embedding_model.encode(question)

        knowledge_col = get_knowledge_collection()

        # Fetch only required fields
        docs = knowledge_col.find(
            {},
            {
                "_id": 0,
                "text": 1,
                "embedding": 1
            }
        )

        scores = []

        for doc in docs:
            emb = doc.get("embedding")
            text = doc.get("text", "")

            if not emb:
                continue

            score = cosine_similarity(q_emb, emb)
            scores.append((score, text))

        if not scores:
            return ""

        # Sort by similarity descending
        scores.sort(key=lambda x: x[0], reverse=True)

        # Return only the best matching context
        best_context = scores[0][1]

        return best_context

    except Exception as e:
        print(f"❌ Retriever Error: {e}")
        return ""
