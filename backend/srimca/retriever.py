import math
from .config import get_knowledge_collection, get_embedding_model


def cosine_similarity(vec1, vec2, eps: float = 1e-12) -> float:
    """Calculate cosine similarity between two vectors.

    Returns a float in the range [-1.0, 1.0]. If the vectors have different
    lengths or one of the vectors has (near) zero norm, this returns 0.0.
    """
    if len(vec1) != len(vec2):
        return 0.0

    # Force float arithmetic to avoid surprising int returns
    dot = sum(float(a) * float(b) for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(float(a) * float(a) for a in vec1))
    norm2 = math.sqrt(sum(float(b) * float(b) for b in vec2))

    if norm1 <= eps or norm2 <= eps:
        return 0.0

    return dot / (norm1 * norm2)


def _ensure_list(x):
    """Convert an embedding-like object to a plain Python list."""
    if x is None:
        return None
    if hasattr(x, "tolist"):
        return x.tolist()
    try:
        return list(x)
    except Exception:
        return None


def retrieve_context(question, top_k: int = 1):
    """Retrieve the most relevant SRIMCA context using embeddings.

    This function is defensive about the knowledge collection API: it first
    tries a `get(include=["documents","embeddings"])` style (used by some
    vectorstore wrappers) and falls back to a `.find()`-style iterator that
    yields documents with `text` and `embedding` keys.

    By default this returns the single best-matching document's text. If
    `top_k > 1` it returns the top_k documents concatenated with two newlines
    between them.
    """
    try:
        # Load embedding model
        embedding_model = get_embedding_model()
        if embedding_model is None:
            return ""

        # Generate embedding for user's question and coerce to a list
        raw_q_emb = embedding_model.encode(question)
        question_embedding = _ensure_list(raw_q_emb)
        if not question_embedding:
            return ""

        # Get knowledge collection
        collection = get_knowledge_collection()
        if collection is None:
            return ""

        # Try the collection.get(...) interface first
        documents = []
        embeddings = []
        if hasattr(collection, "get"):
            try:
                results = collection.get(include=["documents", "embeddings"])
                documents = results.get("documents", []) or []
                embeddings = results.get("embeddings", []) or []
            except Exception:
                documents = []
                embeddings = []

        # Fallback to a Mongo-like find(...) returning docs with text/embedding
        if not documents or not embeddings:
            try:
                cursor = collection.find({}, {"_id": 0, "text": 1, "embedding": 1})
                for d in cursor:
                    text = d.get("text", "")
                    emb = d.get("embedding")
                    if emb is None:
                        continue
                    documents.append(text)
                    embeddings.append(_ensure_list(emb))
            except Exception:
                # If find isn't supported either, try another fallback: maybe
                # the collection itself is an iterable of dicts
                try:
                    for d in collection:
                        if not isinstance(d, dict):
                            continue
                        text = d.get("text", "")
                        emb = d.get("embedding")
                        if emb is None:
                            continue
                        documents.append(text)
                        embeddings.append(_ensure_list(emb))
                except Exception:
                    pass

        if not documents or not embeddings:
            return ""

        # Ensure embeddings are lists of floats
        cleaned = []
        for text, emb in zip(documents, embeddings):
            emb_list = _ensure_list(emb)
            if emb_list is None:
                continue
            cleaned.append((text, emb_list))

        if not cleaned:
            return ""

        # Calculate similarity scores
        scores = []
        for text, emb in cleaned:
            score = cosine_similarity(question_embedding, emb)
            scores.append((score, text))

        # Sort by highest similarity
        scores.sort(key=lambda x: x[0], reverse=True)

        # Return top_k results. For compatibility with previous behaviour we
        # return the best match even if score <= 0. If you want to filter by a
        # minimum similarity threshold, make that configurable instead.
        top_k = max(1, int(top_k or 1))
        selected = [t for _, t in scores[:top_k]]
        if not selected:
            return ""
        if len(selected) == 1:
            return selected[0]
        return "\n\n".join(selected)

    except Exception as e:
        # Keep this simple but explicit so failures are visible in logs
        print(f"❌ Retriever Error: {e}")
        return ""
