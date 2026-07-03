from .loader import load_content

def get_fallback_answer(question):
    q = question.lower().strip()

    content = load_content()
    lines = [line.strip() for line in content.split("\n") if line.strip()]

    # Courses
    if any(word in q for word in ["course", "courses", "programme", "program", "offer"]):
        for line in lines:
            if "offers" in line.lower() or "programme" in line.lower():
                return line

    # Location
    if any(word in q for word in ["where", "location", "located"]):
        for line in lines:
            if "located" in line.lower():
                return line

    # University
    if "university" in q:
        for line in lines:
            if "uka tarsadia" in line.lower():
                return line

    # Vision
    if "vision" in q:
        for line in lines:
            if "vision" in line.lower():
                return line

    # Mission
    if "mission" in q:
        for line in lines:
            if "mission" in line.lower():
                return line

    # Library
    if "library" in q:
        for line in lines:
            if "library" in line.lower():
                return line

    # Internet
    if "internet" in q or "wifi" in q:
        for line in lines:
            if "internet" in line.lower() or "wi-fi" in line.lower():
                return line

    # MBA
    if "mba" in q:
        for line in lines:
            if "mba" in line.lower():
                return line

    # MCA
    if "mca" in q:
        for line in lines:
            if "mca" in line.lower():
                return line

    # Full Name
    if any(word in q for word in ["full name", "what is srimca", "srimca full form"]):
        for line in lines:
            if "full name" in line.lower():
                return line

    # Generic keyword search
    keywords = [w for w in q.split() if len(w) > 2]

    best_line = None
    best_score = 0

    for line in lines:
        score = sum(1 for word in keywords if word in line.lower())

        if score > best_score:
            best_score = score
            best_line = line

    if best_line:
        return best_line

    return "Sorry, I could not find information related to your question."
