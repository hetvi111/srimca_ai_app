import re
from .loader import load_lines

def get_exact_answer(question: str):
    """Get exact timetable schedule for a requested day."""
    if not question:
        return None

    q = question.lower()
    
    # Check if this is a timetable/schedule query
    timetable_keywords = ["timetable", "time table", "schedule", "class", "lecture", "period", "routine", "subject"]
    has_timetable_intent = any(k in q for k in timetable_keywords)

    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    found_day = next((d for d in days if d in q), None)

    if not found_day and not has_timetable_intent:
        return None

    lines = load_lines()

    # Extract time filter if present (e.g. "10:30" or "08:30-10:30")
    time_match = re.search(r'(\d{1,2}):(\d{2})', q)

    if found_day:
        day_lines = [
            line.strip() for line in lines
            if 'mca 2nd semester' in line.lower() and found_day in line.lower()
        ]

        if day_lines:
            if time_match:
                target_h = int(time_match.group(1))
                for line in day_lines:
                    line_time = re.search(r'(\d{1,2}):(\d{2})', line)
                    if line_time and int(line_time.group(1)) == target_h:
                        return f"**{found_day.capitalize()} at {line_time.group(0)}:**\n{line}"

            # Format the day's timetable nicely
            formatted_schedule = []
            for line in day_lines:
                # Remove redundant prefix for cleaner bullets
                clean = re.sub(r'(?i)mca\s+2nd\s+semester\s+' + found_day + r'\s*', '', line).strip()
                if clean.lower().startswith('has '):
                    clean = clean[4:].strip()
                elif clean.lower().startswith('is '):
                    clean = clean[3:].strip()
                formatted_schedule.append(f"• {clean}")

            return (
                f"**MCA 2nd Semester Timetable — {found_day.capitalize()}:**\n\n"
                + "\n".join(formatted_schedule)
            )

    # If general timetable query without specific day
    if has_timetable_intent and 'mca' in q:
        return (
            "**MCA 2nd Semester Class Schedule Overview:**\n\n"
            "• **Monday:** Laravel Practical (8:30-10:30), iOS Theory, Elective, ASP.NET, Laravel\n"
            "• **Tuesday:** Laravel Theory, iOS Theory, Python, ASP.NET, Laravel\n"
            "• **Wednesday:** iOS Practical (8:30-10:30), ASP.NET, Python, Project Lab\n"
            "• **Thursday:** ASP.NET Practical (8:30-10:30), Laravel, iOS, Technical Seminar\n"
            "• **Friday:** Python Practical (8:30-10:30), Elective Theory, Lab Practice\n\n"
            "*Ask for a specific day (e.g. 'Monday timetable') for exact class timings!*"
        )

    return None
