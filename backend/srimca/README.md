# SRIMCA AI Assistant

A RAG (Retrieval-Augmented Generation) based AI assistant that answers questions using knowledge from text files.

## Setup Instructions

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure OpenAI API Key
Create a `.env` file in this directory:
```bash
copy .env.example .env
```

Then edit `.env` and add your OpenAI API key:
```
OPENAI_API_KEY=your_actual_api_key_here
```

### 3. Add Your Data Files
Place your `.txt` files in the `data/` folder. The assistant will automatically load and index all `.txt` files from this folder.

### 4. Run the Assistant

**Open PowerShell or Command Prompt** and navigate to this folder:
```bash
cd c:\Users\malav\Desktop\srimca
```

Then run:
```bash
python srimca_rag.py
```

### 5. Ask Questions
Once the script starts, you'll see:
```
Building / loading SRIMCA knowledge base...
Ready. Ask your questions about SRIMCA (type 'exit' to quit).

You: 
```

Type your questions and press Enter. Type `exit` to quit.

## Example Questions
- "What is SRIMCA?"
- "What programs does SRIMCA offer?"
- "Where is SRIMCA located?"

## Notes
- The first run will index all `.txt` files in the `data/` folder (this may take a minute)
- Subsequent runs will be faster as the vector database is already built
- Make sure you have an active internet connection for OpenAI API calls