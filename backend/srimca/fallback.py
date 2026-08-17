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

    # 5. Courses / Programs Offered
    if any(w in q for w in ['course', 'courses', 'program', 'programs', 'degree', 'branch', 'offer', 'curriculum', 'stream']):
        return (
            "**Academic Programmes Offered at SRIMCA:**\n\n"
            "1. **MCA** (Master of Computer Applications) - 2 Years\n"
            "2. **BCA** (Bachelor of Computer Applications) - 3 Years\n"
            "3. **Integrated MCA** - 5 Years\n"
            "4. **MBA** (Master of Business Administration) - 2 Years\n"
            "5. **Integrated MBA (IMBA)** - 5 Years\n\n"
            "All courses feature industry-aligned syllabus including AI, Cloud Computing, Full-stack Web Development, and Data Science."
        )

    # 6. Admission / Eligibility / ACPC
    if any(w in q for w in ['admission', 'apply', 'eligibility', 'acpc', 'enroll', 'seat', 'criteria', 'entrance', 'fees', 'fee']):
        return (
            "**SRIMCA Admissions & Eligibility:**\n\n"
            "• **MCA Admissions:** Governed by **ACPC** (Admission Committee for Professional Courses, Gujarat) & Management Quota.\n"
            "• **BCA Admissions:** Direct admission through the **UTU Admission Portal** based on 12th standard (HSC) merit.\n"
            "• **MBA Admissions:** Through ACPC CMAT / Management quota merit list.\n\n"
            "You can apply online via the official university admission portal or visit the campus admission desk."
        )

    # 7. Placements & Recruiters
    if any(w in q for w in ['placement', 'package', 'salary', 'recruiter', 'company', 'companies', 'job', 'hiring', 'interview']):
        return (
            "**SRIMCA Training & Placement:**\n\n"
            "SRIMCA has an active Training and Placement Cell with excellent campus recruitment records.\n"
            "• **Top Recruiters:** TCS, Infosys, Wipro, L&T Infotech, Capgemini, TatvaSoft, Bacancy, WebOccult, Dhyey Consulting, and more.\n"
            "• **Support:** Pre-placement training, mock technical interviews, aptitude tests, and industrial internships."
        )

    # 8. Facilities / Infrastructure / Labs / Hostel / Wi-Fi
    if any(w in q for w in ['facility', 'facilities', 'lab', 'computer', 'hostel', 'wifi', 'wi-fi', 'internet', 'library', 'canteen', 'cafeteria', 'bus', 'transport']):
        return (
            "**SRIMCA Campus Facilities:**\n\n"
            "• **Computer Labs:** Over 250+ high-performance systems with latest development tools.\n"
            "• **Internet:** 200 Mbps dedicated leased-line with high-speed Wi-Fi across campus.\n"
            "• **Library:** Extensive collection of books, IEEE/ACM journals, and digital e-learning resources.\n"
            "• **Infrastructure:** Air-conditioned auditorium, seminar halls, and smart classrooms.\n"
            "• **Hostel & Transport:** On-campus AC/Non-AC hostels for boys and girls, plus bus service covering Surat, Navsari, and Bardoli."
        )

    # 9. Vision & Mission
    if 'vision' in q:
        return "**SRIMCA Vision:** To become a globally recognized premier educational institute for academic excellence, innovation, and character building."

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
