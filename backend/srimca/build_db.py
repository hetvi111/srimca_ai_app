from .config import knowledge_col, embedding_model
from .loader import load_content

def build_db():
    """Build vector database using local embeddings (FREE)."""
    print("🗑️  Clearing existing knowledge base...")
    knowledge_col.delete_many({})
    
    print("📚 Loading text files...")
    content = load_content()
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    
    print(f"🔧 Creating embeddings for {len(lines)} chunks...")

    if embedding_model is None:
        print("⚠️  Embedding model unavailable; storing text-only knowledge entries.")
        for line in lines:
            knowledge_col.insert_one({
                "text": line
            })
        print(f"✅ Knowledge DB built with {len(lines)} text-only chunks")
        return

    # Create embeddings locally (free, no API)
    embeddings = embedding_model.encode(lines)

    for line, embedding in zip(lines, embeddings):
        knowledge_col.insert_one({
            "text": line,
            "embedding": embedding.tolist()
        })
    
    print(f"✅ Knowledge DB built with {len(lines)} chunks")


if __name__ == "__main__":
    build_db()
