import os
from pymongo import MongoClient
from sentence_transformers import SentenceTransformer
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# Configuration
DATA_DIR = "data"
MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net")
DB_NAME = os.getenv("DB_NAME", "srimca_ai")
COLLECTION = os.getenv("COLLECTION_KNOWLEDGE", "knowledge")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# MongoDB Connection
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
knowledge_col = db[COLLECTION]

# Free local embedding model (no API cost)
embedding_model = SentenceTransformer("all-MiniLM-L6-v2")

# OpenAI client (optional - for GPT answers if you have credits)
openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None
