from .loader import load_content

def get_fallback_answer(question):
    q = question.lower().strip()
    content = load_content()

    # Introduction queries
    intro_keywords = [
        "introduction",
        "about srimca",
        "overview",
        "college",
        "institute",
        "facilities",
        "courses",
        "programs",
        "programmes"
    ]

    if any(word in q for word in intro_keywords):
        return content[:1500]

    # Full Name
    if "full name" in q:
        for line in content.splitlines():
            if "full name" in line.lower():
                return line.strip()

    # Location
    if "where" in q or "located" in q:
        for line in content.splitlines():
            if "located" in line.lower():
                return line.strip()

    # University
    if "university" in q:
        for line in content.splitlines():
            if "uka tarsadia" in line.lower():
                return line.strip()

    # Vision
    if "vision" in q:
        for line in content.splitlines():
            if "vision" in line.lower():
                return line.strip()

    # Mission
    if "mission" in q:
        for line in content.splitlines():
            if "mission" in line.lower():
                return line.strip()

    # Courses / Programs
    if any(x in q for x in ["course", "courses", "program", "programme"]):
        result = []
        for line in content.splitlines():
            if any(
                word in line.lower()
                for word in ["bca", "mca", "mba", "program", "programme"]
            ):
                result.append(line.strip())

        if result:
            return "\n".join(result[:10])

    # Default fallback
    return content[:1000]
