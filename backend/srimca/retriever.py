import math
from .config import get_knowledge_collection, get_embedding_model


def cosine_similarity(vec1, vec2):
    """
    Calculate cosine similarity between two vectors.
    """
    if len(vec1) != len(vec2):
        return 0

    dot = sum(a * b for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(a * a for a in vec1))
    norm2 = math.sqrt(sum(b * b for b in vec2))

    if norm1 == 0 or norm2 == 0:
        return 0

    return dot / (norm1 * norm2)


def retrieve_context(question, top_k=1):
    """
    Retrieve the most relevant SRIMCA context using embeddings.
    Optimized for Render deployment.
    """

    try:
        # Load embedding model
        embedding_model = get_embedding_model()

        # Generate embedding for user's question
        question_embedding = embedding_model.encode(question).tolist()

        # Get knowledge collection
        collection = get_knowledge_collection()

        # Fetch all stored documents and embeddings
        results = collection.get(
            include=["documents", "embeddings"]
        )

        documents = results.get("documents", [])
        embeddings = results.get("embeddings", [])

        if not documents or not embeddings:
            return ""

        # Calculate similarity scores
        scores = []

        for text, embedding in zip(documents, embeddings):
            score = cosine_similarity(question_embedding, embedding)
            scores.append((score, text))

        # Sort by highest similarity
        scores.sort(key=lambda x: x[0], reverse=True)

        # Return the best matching context
        if scores and scores[0][0] > 0:
            return scores[0][1]

        return ""

    except Exception as e:
        print(f"❌ Retriever Error: {e}")
        return ""
