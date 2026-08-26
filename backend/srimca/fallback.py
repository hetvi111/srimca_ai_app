import re
from .loader import load_lines

def get_fallback_answer(question: str) -> str:
    """Intelligent and comprehensive answer engine for SRIMCA AI."""
    if not question or not question.strip():
        return "Please ask a question about SRIMCA, courses, timetable, facilities, or admissions."

    q = question.lower().strip()
    clean_q = re.sub(r'[^\w\s]', ' ', q)
    words = clean_q.split()

    lines = load_lines()

    # 1. Greetings & Bot Identity
    if any(g == clean_q.strip() or clean_q.strip().startswith(g + ' ') for g in ['hi', 'hello', 'hey', 'namaste', 'good morning', 'good afternoon', 'good evening']):
        return (
            "Hello! I am **SRIMCA AI Assistant**, your smart college guide. "
            "You can ask me about:\n\n"
            "• College details, Courses & Admissions (BCA, MCA, MBA)\n"
            "• Class Timetables & Schedules\n"
            "• Campus Facilities, Labs, Library & Transport\n"
            "• Placement & Career opportunities"
        )

    if any(phrase in q for phrase in ['who are you', 'what are you', 'your name', 'about you', 'introduce yourself']):
        return (
            "I am **SRIMCA AI**, the intelligent campus assistant for Shrimad Rajchandra Institute of "
            "Management and Computer Application (SRIMCA), Uka Tarsadia University. I'm here to help "
            "students, faculty, and visitors with instant academic and campus information!"
        )

    # 2. What is SRIMCA / About SRIMCA / Full Form
    if any(phrase in q for phrase in [
        'what is srimca', 'about srimca', 'full name', 'full form', 'tell me about srimca',
        'what is the full form of srimca', 'what does srimca stand for', 'define srimca'
    ]) or (len(words) <= 2 and 'srimca' in words):
        return (
            "**SRIMCA** stands for **Shrimad Rajchandra Institute of Management and Computer Application**.\n\n"
            "• **Affiliation:** Constituent institute of **Uka Tarsadia University (UTU)**, Maliba Campus, Bardoli, Surat.\n"
            "• **Approvals:** Approved by **AICTE**, New Delhi & Government of Gujarat.\n"
            "• **Established:** MCA established in 2002; MBA established in 2004.\n"
            "• **Programmes Offered:** MCA, BCA, Integrated MCA, MBA, Integrated MBA."
        )

    # 3. Location / Address / Campus
    if any(w in q for w in ['where', 'location', 'address', 'located', 'place', 'campus', 'how to reach', 'map', 'city']):
        return (
            "**SRIMCA Location & Campus:**\n\n"
            "• **Address:** Maliba Campus, Gopal Vidyanagar, Bardoli-Mahuva Road, Tarsadi, Surat, Gujarat - 394350.\n"
            "• **University:** Uka Tarsadia University (UTU)\n"
            "• **Transportation:** Bus services available covering Surat, Navsari, Bardoli, Vyara, and surrounding areas."
        )

    # 4. University / UTU affiliation
    if any(w in q for w in ['university', 'utu', 'uka tarsadia', 'affiliated', 'affiliation', 'accreditation']):
        return (
            "SRIMCA is a premier constituent institute of **Uka Tarsadia University (UTU)**, established under Gujarat Private Universities Act. "
            "All technical programs are approved by **AICTE**, New Delhi."
        )

    # 5. Courses & Admission
    if any(w in q for w in ['course', 'courses', 'program', 'programmes', 'degree', 'admission', 'eligibility', 'seat', 'intake', 'bca', 'mca', 'mba']):
        return (
            "**SRIMCA Programmes & Admissions:**\n\n"
            "• **MCA (Master of Computer Applications):** 2-Year PG Degree (Intake: 120 seats). Eligibility: Passed BCA/B.Sc/B.Com/B.A. with Mathematics at 10+2 level or Graduation level.\n"
            "• **BCA (Bachelor of Computer Applications):** 3-Year UG Degree (Intake: 180 seats). Eligibility: 12th Pass from recognized board.\n"
            "• **Integrated MCA (BCA + MCA):** 5-Year Dual Degree Program.\n"
            "• **MBA (Master of Business Administration):** 2-Year PG Degree (Specializations: Finance, HR, Marketing).\n"
            "• **Integrated MBA:** 5-Year Integrated Management Degree."
        )

    # 6. Facilities & Infrastructure
    if any(w in q for w in ['facility', 'facilities', 'lab', 'labs', 'library', 'canteen', 'hostel', 'sports', 'wifi', 'internet']):
        return (
            "**SRIMCA Campus Facilities:**\n\n"
            "• **Computer Labs:** High-speed internet, modern desktop systems, advanced software & development tools.\n"
            "• **Central Library:** Thousands of books, international journals, IEEE digital subscription, and e-learning resources.\n"
            "• **Hostel & Mess:** Separate secure hostels for boys and girls with 24/7 security and hygienic food.\n"
            "• **Sports & Gym:** Playground for cricket, football, volleyball, indoor games, and modern gymnasium."
        )

    # 7. Placements & Career
    if any(w in q for w in ['placement', 'placements', 'job', 'salary', 'package', 'company', 'companies', 'recruiters']):
        return (
            "**SRIMCA Training & Placement Cell:**\n\n"
            "• Strong placement record with top IT and Management recruiters.\n"
            "• **Top Recruiters:** TCS, Infosys, Wipro, Capgemini, L&T Infotech, Gateway Group, TatvaSoft, Crest Data Systems.\n"
            "• Pre-placement training including aptitude tests, mock interviews, and technical workshops."
        )

    # 8. Principal & Contact
    if any(w in q for w in ['contact', 'phone', 'email', 'number', 'call', 'principal', 'director', 'hod']):
        return (
            "**SRIMCA Contact Information:**\n\n"
            "• **Email:** director.srimca@utu.ac.in\n"
            "• **Website:** https://srimca.edu.in / https://utu.ac.in\n"
            "• **Phone:** +91 (02625) 290020 / 290074\n"
            "• **Address:** Maliba Campus, Gopal Vidyanagar, Bardoli-Mahuva Road, Tarsadi, Surat - 394350."
        )

    # 9. Mission & Vision
    if 'vision' in q:
        return "**SRIMCA Vision:** To become a center of excellence in management and computer education by producing competent professionals with strong ethical values."
    if 'mission' in q:
        return "**SRIMCA Mission:** To remain on the cutting edge of education, research, industry partnerships, and moral commitment to society."

    # 10. Keyword Search across loaded lines
    stop_words = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'tell', 'me', 'please', 'give', 'detail', 'details', 'about'}
    query_keywords = [w for w in words if w not in stop_words and len(w) > 2]

    if query_keywords:
        matching_lines = []
        for line in lines:
            line_lower = line.lower()
            match_count = sum(1 for kw in query_keywords if kw in line_lower)
            if match_count > 0:
                matching_lines.append((match_count, line))

        if matching_lines:
            matching_lines.sort(key=lambda x: x[0], reverse=True)
            top_matches = [m[1] for m in matching_lines[:4]]
            return "\n\n".join(top_matches)

    # 11. General Fallback
    return (
        "SRIMCA (Shrimad Rajchandra Institute of Management and Computer Application) is a constituent college of "
        "Uka Tarsadia University (UTU), Bardoli, offering BCA, MCA, and MBA programs approved by AICTE. "
        "Please feel free to ask about courses, timetable, campus facilities, or admissions!"
    )
