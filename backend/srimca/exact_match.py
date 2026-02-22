import re
from loader import load_content

def get_exact_answer(question):
    """Get exact answer for timetable queries using pattern matching."""
    q = question.lower()
    content = load_content()
    all_lines = content.split('\n')
    
    # Extract day
    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    found_day = next((d for d in days if d in q), None)
    
    # Extract time
    time_match = re.search(r'(\d{1,2}):(\d{2})\s*[-–to]+\s*(\d{1,2}):(\d{2})', q)
    
    if found_day:
        for i, line in enumerate(all_lines):
            line_l = line.lower().strip()
            
            # Must be a 2nd semester timetable line
            if 'mca 2nd semester' not in line_l:
                continue
            if found_day not in line_l:
                continue
            
            # Collect all timetable lines for this day
            timetable = []
            for j in range(i, len(all_lines)):
                tl = all_lines[j].strip()
                if not tl:
                    continue
                if 'mca' not in tl.lower() or 'semester' not in tl.lower():
                    break
                timetable.append(tl)
            
            if timetable:
                if time_match:
                    # Exact time match
                    start_h = int(time_match.group(1))
                    for tl in timetable:
                        tl_match = re.search(r'(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})', tl)
                        if tl_match:
                            tl_start = int(tl_match.group(1))
                            if tl_start == start_h:
                                return tl.strip()
                else:
                    return f"MCA 2nd Semester {found_day.capitalize()}:\n" + "\n".join(timetable)
    
    return None
