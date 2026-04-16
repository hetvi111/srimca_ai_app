from .loader import load_content

def get_fallback_answer(question):
    """Keyword-based fallback when GPT is unavailable."""
    q = question.lower().strip()
    content = load_content()
    all_lines = content.split('\n')
    
    # Direct patterns
    if 'full name' in q:
        for line in all_lines:
            if 'full name' in line.lower():
                return line.strip()
    
    if 'located' in q or 'where' in q:
        for line in all_lines:
            if 'located' in line.lower():
                return line.strip()
    
    if 'university' in q:
        for line in all_lines:
            if 'uka tarsadia' in line.lower():
                return line.strip()
    
    if 'vision' in q:
        for line in all_lines:
            if 'vision' in line.lower():
                return line.strip()
    
    if 'mission' in q:
        for line in all_lines:
            if 'mission' in line.lower():
                return line.strip()
    
    if 'program' in q:
        for line in all_lines:
            if 'programme' in line.lower():
                return line.strip()
    
    # BCA semester specific
    if 'bca' in q:
        for line in all_lines:
            if 'bca' in line.lower() or '4th' in line.lower() and '6th' in line.lower():
                return line.strip()
    
    # Keyword scoring
    stop = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'we', 'they', 'srimca', 'mca', 'mba', 'bca'}
    keywords = [w for w in q.split() if w not in stop and len(w) > 2]
    
    best = None
    best_score = 0
    
    for line in all_lines:
        score = sum(1 for k in keywords if k in line.lower())
        if score > best_score:
            best_score = score
            best = line
    
    if best and best_score >= 1:
        return best.strip()
    
    for line in all_lines:
        if 'srimca' in line.lower() and len(line) > 30:
            return line.strip()
    
    return "I don't have that information."
