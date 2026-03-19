import os
from pymongo import MongoClient
from dotenv import load_dotenv
try:
    from openai import OpenAI
except Exception:
    OpenAI = None

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

load_dotenv()

# Set HF_TOKEN for Hugging Face Hub (avoids unauth warnings, enables higher limits)
os.environ['HF_TOKEN'] = os.getenv('HF_TOKEN', '')

# Configuration
DATA_DIR = os.path.join(SCRIPT_DIR, "data")
MONGO_URI = os.getenv("MONGODB_URI") or os.getenv("MONGO_URI", "mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net")
DB_NAME = os.getenv("MONGODB_DB_NAME") or os.getenv("DB_NAME", "srimca_ai")
COLLECTION = os.getenv("COLLECTION_KNOWLEDGE", "knowledge")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# MongoDB Connection (lazy-loaded to avoid blocking web startup)
_knowledge_col = None


def get_knowledge_collection():
    """Return MongoDB collection, creating the client on first use only."""
    global _knowledge_col

    if _knowledge_col is not None:
        return _knowledge_col

    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000, connectTimeoutMS=5000)
    db = client[DB_NAME]
    _knowledge_col = db[COLLECTION]
    return _knowledge_col

# Free local embedding model (no API cost)
# Keep startup resilient when sentence-transformers is unavailable.
# Load lazily so web server can bind port quickly on cold starts.
_embedding_model = None
_embedding_model_initialized = False


def get_embedding_model():
    """Return cached embedding model, loading it on first use only."""
    global _embedding_model, _embedding_model_initialized

    if _embedding_model_initialized:
        return _embedding_model

    _embedding_model_initialized = True
    try:
        from sentence_transformers import SentenceTransformer
    except Exception:
        print("Warning: sentence-transformers not available; semantic retrieval disabled.")
        _embedding_model = None
        return _embedding_model

    try:
        _embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
    except Exception as exc:
        print(f"Warning: failed to load embedding model: {exc}")
        _embedding_model = None

    return _embedding_model

# OpenAI client (optional - for GPT answers if you have credits)
if OpenAI is not None and OPENAI_API_KEY:
    openai_client = OpenAI(api_key=OPENAI_API_KEY)
else:
    openai_client = None
