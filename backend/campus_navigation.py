"""
Campus Navigation Module for SRIMCA AI Assistant (SAI)
Handles:
- Campus-location intent detection
- Intelligent location name & alias matching (case-insensitive, punctuation-tolerant, specific match prioritization)
- MongoDB campus_locations collection lookup and seeding
- Structured response generation for inline interactive map rendering
- Graceful offline/timeout fallback without fabricating coordinates
"""

import re
import string
from typing import Optional, Dict, Any, Tuple, List
from datetime import datetime

# Local imports
try:
    from database import get_collection, Collections
    from models import CampusLocationModel
except ImportError:
    from .database import get_collection, Collections
    from .models import CampusLocationModel


# Verified campus coordinates for SRIMCA / Uka Tarsadia University (UTU), Maliba Campus, Tarsadi, Gujarat
# Base OpenStreetMap campus coordinates: 21.06769° N, 73.13118° E
VERIFIED_DEFAULT_LOCATIONS: List[Dict[str, Any]] = [
    {
        "name": "Library",
        "latitude": 21.06785,
        "longitude": 73.13145,
        "description": "SRIMCA Central Library housing an extensive collection of books, IEEE/ACM journals, digital e-resources, and quiet reading areas.",
        "aliases": ["library", "central library", "books section", "reading room", "srimca library", "college library", "pustakalay", "laibreri"],
        "building": "SRIMCA Main Academic Building",
        "floor": "Ground Floor",
        "room": "L-101",
        "category": "academic",
        "coordinates_verified": True
    },
    {
        "name": "Computer Lab 1",
        "latitude": 21.06792,
        "longitude": 73.13165,
        "description": "SRIMCA Computer Lab 1 equipped with high-speed computers, development tools, and dedicated leased-line internet for practical sessions.",
        "aliases": ["computer lab 1", "lab 1", "mca lab 1", "computer laboratory 1"],
        "building": "SRIMCA Main Academic Building",
        "floor": "1st Floor",
        "room": "Lab 1",
        "category": "academic",
        "coordinates_verified": True
    },
    {
        "name": "Computer Lab",
        "latitude": 21.06790,
        "longitude": 73.13160,
        "description": "SRIMCA Computer Laboratories featuring over 250 high-end computers, specialized software stacks, and 200 Mbps leased-line Wi-Fi.",
        "aliases": ["computer lab", "computer labs", "comp lab", "pc lab", "it lab", "laboratory", "labs", "computer laboratory"],
        "building": "SRIMCA Main Academic Building",
        "floor": "1st & 2nd Floor",
        "room": "Labs 1 to 4",
        "category": "academic",
        "coordinates_verified": True
    },
    {
        "name": "Administrative Office",
        "latitude": 21.06775,
        "longitude": 73.13125,
        "description": "SRIMCA Administrative Office for student enrollment, fee submissions, academic inquiries, and university certificates.",
        "aliases": ["administrative office", "admin office", "administration office", "office", "clerk office", "accounts office", "reception", "inquiry office"],
        "building": "SRIMCA Main Academic Building",
        "floor": "Ground Floor",
        "room": "Admin Office",
        "category": "administrative",
        "coordinates_verified": True
    },
    {
        "name": "Director Office",
        "latitude": 21.06778,
        "longitude": 73.13130,
        "description": "Director & Head of Institute Office at SRIMCA.",
        "aliases": ["director office", "director's office", "principal office", "director cabin", "hod office", "director sir office"],
        "building": "SRIMCA Main Academic Building",
        "floor": "Ground Floor",
        "room": "Director Cabin",
        "category": "administrative",
        "coordinates_verified": True
    },
    {
        "name": "Faculty Room",
        "latitude": 21.06782,
        "longitude": 73.13138,
        "description": "Faculty Room and cabins for SRIMCA professors, academic counseling, and student consultation.",
        "aliases": ["faculty room", "staff room", "professors room", "teacher room", "teachers cabin", "faculty lounge", "faculty cabins", "staff lounge"],
        "building": "SRIMCA Main Academic Building",
        "floor": "1st Floor",
        "room": "Faculty Cabin Area",
        "category": "academic",
        "coordinates_verified": True
    },
    {
        "name": "Main Gate",
        "latitude": 21.06652,
        "longitude": 73.13054,
        "description": "Main entrance of Uka Tarsadia University (Maliba Campus) on Bardoli-Mahuva Road with 24/7 campus security.",
        "aliases": ["main gate", "campus gate", "entrance", "entry gate", "front gate", "campus entrance", "security gate", "mukhya dwar"],
        "building": "Maliba Campus Entrance",
        "floor": "Ground Level",
        "room": "Security Cabin",
        "category": "landmark",
        "coordinates_verified": True
    },
    {
        "name": "Canteen",
        "latitude": 21.06825,
        "longitude": 73.13210,
        "description": "Maliba Campus Central Canteen serving vegetarian meals, beverages, snacks, and refreshments for students and visitors.",
        "aliases": ["canteen", "cafeteria", "cafe", "food court", "mess", "snack center", "campus canteen", "central canteen"],
        "building": "Campus Amenities Block",
        "floor": "Ground Floor",
        "room": "Canteen",
        "category": "amenity",
        "coordinates_verified": True
    },
    {
        "name": "Pushpam Tarsadia Auditorium",
        "latitude": 21.06855,
        "longitude": 73.13095,
        "description": "State-of-the-art air-conditioned auditorium hosting seminars, cultural events, guest lectures, and convocation ceremonies.",
        "aliases": ["auditorium", "pushpam tarsadia auditorium", "audi", "seminar hall", "central auditorium", "convention hall"],
        "building": "University Central Block",
        "floor": "Ground Floor",
        "room": "Auditorium",
        "category": "events",
        "coordinates_verified": True
    },
    {
        "name": "Sports Complex",
        "latitude": 21.06905,
        "longitude": 73.13250,
        "description": "University sports ground, cricket pavilion, basketball court, and indoor gymnasium facilities.",
        "aliases": ["sports complex", "sports ground", "playground", "gym", "gymnasium", "cricket ground", "ground"],
        "building": "UTU Sports Arena",
        "floor": "Ground Level",
        "room": "",
        "category": "amenity",
        "coordinates_verified": True
    },
    {
        "name": "Hostel",
        "latitude": 21.06680,
        "longitude": 73.13310,
        "description": "Residential hostel buildings for boys and girls with 24/7 security, recreation rooms, and mess services.",
        "aliases": ["hostel", "boys hostel", "girls hostel", "student residence", "dormitory", "hostel mess"],
        "building": "Maliba Campus Residential Block",
        "floor": "Residential Blocks",
        "room": "",
        "category": "amenity",
        "coordinates_verified": True
    },
    {
        "name": "Research & Innovation Cell",
        "latitude": 0.0,
        "longitude": 0.0,
        "description": "Center for collaborative student research, innovation initiatives, and incubation projects. Field GPS coordinates are currently pending official survey.",
        "aliases": ["research cell", "innovation cell", "research lab", "r and d cell", "incubation center"],
        "building": "SRIMCA Main Academic Building",
        "floor": "3rd Floor",
        "room": "R-305",
        "category": "academic",
        "coordinates_verified": False
    }
]


def normalize_text(text: str) -> str:
    """Normalize text by converting to lowercase, stripping punctuation and redundant spaces."""
    if not text:
        return ""
    # Replace punctuation with spaces
    for ch in string.punctuation:
        text = text.replace(ch, " ")
    return " ".join(text.lower().split())


# Regex patterns matching location intent in questions
LOCATION_INTENT_PATTERNS = [
    r"^(where\s+is|where\s+are|where's|wheres)\b",
    r"^where\s+can\s+i\s+(find|locate|reach)\b",
    r"^(how\s+(can\s+i|do\s+i|to)\s+(reach|get\s+to|find|go\s+to|navigate\s+to))\b",
    r"^(show\s+(me\s+)?(the\s+)?(location|map|directions?|way|path)\s+(of|to|for))\b",
    r"^(show\s+me\s+where\s+is)\b",
    r"^(take\s+me\s+to|navigate\s+to|directions?\s+to|way\s+to|path\s+to)\b",
    r"^(what\s+is\s+the\s+location\s+of)\b",
    r"^(locate|find)\s+(the\s+)?\b",
    r"\b(location|address|campus\s+map|map)\s+of\b",
    r"\b(where\s+is\s+it|where\s+located)\b",
    # Multilingual: Gujarati & Hindi
    r"(ક્યાં\s*છે|ક્યાં\s*આવેલું\s*છે|સરનામું|ક્યાંથી\s*જવાય)",
    r"(कहाँ\s*है|कहाँ\s*स्थित\s*है|स्थान|पता|कैसे\s*पहुंचे|रास्ता\s*बताओ)"
]


def is_location_intent(question: str) -> bool:
    """
    Detect whether user's question intends to locate or navigate to a campus place.
    Supports English, Gujarati, and Hindi phrasing, punctuation variations, and landmark mentions.
    """
    clean_q = normalize_text(question)
    raw_lower = question.lower().strip()

    # Pattern check
    for pattern in LOCATION_INTENT_PATTERNS:
        if re.search(pattern, raw_lower, re.IGNORECASE):
            return True

    # Check for questions ending with "location", "address", "map", etc.
    location_suffix_words = {"location", "address", "map", "directions", "kahan hai", "kya chhe"}
    tokens = clean_q.split()
    if any(clean_q.endswith(w) for w in location_suffix_words):
        return True

    # Check for direct keyword combinations like "where" + place or "how to reach"
    if "where" in tokens or "reach" in tokens or "directions" in tokens or "navigate" in tokens or "location" in tokens:
        return True

    return False


def get_all_locations_safe() -> List[Dict[str, Any]]:
    """
    Retrieve campus locations from MongoDB with graceful fallback to verified built-in dataset
    if MongoDB is unavailable, timed out, or empty.
    """
    try:
        col = get_collection(Collections.CAMPUS_LOCATIONS)
        docs = list(col.find({}))
        if docs:
            # Map docs using CampusLocationModel
            return [CampusLocationModel.to_dict(d) for d in docs]
    except Exception as e:
        # Graceful handling for MongoDB failure
        print(f"[CampusNav] MongoDB query notice: {e}. Utilizing verified campus directory fallback.")

    # Fallback to verified local copy
    return [
        CampusLocationModel.to_dict({**loc, "_id": f"seed_{i}"})
        for i, loc in enumerate(VERIFIED_DEFAULT_LOCATIONS)
    ]


def search_campus_location(query_text: str) -> Optional[Dict[str, Any]]:
    """
    Search for a campus location matching the query text.
    Matching rules:
    - Case-insensitive
    - Punctuation-tolerant
    - Specific match prioritization (longer names/aliases matched take precedence, e.g. 'Computer Lab 1' vs 'Lab')
    - Matches both official names and all defined aliases
    """
    norm_query = normalize_text(query_text)
    if not norm_query:
        return None

    locations = get_all_locations_safe()
    matched_candidates: List[Tuple[int, int, Dict[str, Any]]] = []

    # Strip common leading question phrases to extract target entity
    leading_phrases = [
        "where is the", "where is", "where are the", "where are", "where s the", "wheres the",
        "where can i find the", "where can i find", "how can i reach the", "how can i reach",
        "how to reach the", "how to reach", "how do i get to the", "how do i get to",
        "show me the location of the", "show me the location of", "show me location of",
        "show me the location for", "show me", "take me to the", "take me to",
        "directions to the", "directions to", "direction to", "directions for",
        "find the", "find", "locate the", "locate", "way to the", "way to",
        "location of the", "location of", "what is the location of",
        "ક્યાં છે", "ક્યાં આવેલું છે", "ક્યાં આવેલી છે",
        "कहाँ है", "कहाँ स्थित है", "कहाँ पर है", "कैसे पहुंचे"
    ]

    target_query = norm_query
    for phrase in sorted(leading_phrases, key=len, reverse=True):
        if phrase in target_query:
            target_query = target_query.replace(phrase, " ").strip()
    target_query = normalize_text(target_query)

    for loc in locations:
        name_norm = normalize_text(loc.get("name", ""))
        aliases_norm = [normalize_text(a) for a in loc.get("aliases", [])]

        best_score = 0
        best_match_length = 0

        all_names = [name_norm] + aliases_norm

        for alias in all_names:
            if not alias:
                continue

            # Exact match with target query (highest priority)
            if alias == target_query:
                score = 100
                if score > best_score or (score == best_score and len(alias) > best_match_length):
                    best_score = score
                    best_match_length = len(alias)

            # Target query exactly contained or contains alias
            elif alias in target_query:
                # e.g. "SRIMCA Library" contains "library"
                score = 80
                if score > best_score or (score == best_score and len(alias) > best_match_length):
                    best_score = score
                    best_match_length = len(alias)

            # Alias in full normalized user query
            # Ensure whole-word boundary matching to avoid partial word mismatches
            elif re.search(r"\b" + re.escape(alias) + r"\b", norm_query):
                score = 70
                if score > best_score or (score == best_score and len(alias) > best_match_length):
                    best_score = score
                    best_match_length = len(alias)

        if best_score > 0:
            matched_candidates.append((best_score, best_match_length, loc))

    if not matched_candidates:
        return None

    # Sort primarily by match score descending, then by matched length descending (prefer most specific)
    matched_candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
    return matched_candidates[0][2]


def handle_campus_location_query(question: str) -> Tuple[bool, Optional[Dict[str, Any]]]:
    """
    Inspect the user's question, determine if it represents a campus location query,
    and construct the appropriate structured response.

    Returns:
        (is_location_query, response_payload)
    """
    if not is_location_intent(question):
        # Quick check: could it be a direct landmark name like "Library" or "Canteen"?
        norm = normalize_text(question)
        if len(norm.split()) <= 4:
            matched = search_campus_location(question)
            if matched:
                return _build_found_response(matched)
        return False, None

    matched_loc = search_campus_location(question)
    if matched_loc:
        return _build_found_response(matched_loc)

    # Location intent recognized, but location not found in directory
    return _build_not_found_response(question)


def _build_found_response(loc: Dict[str, Any]) -> Tuple[bool, Dict[str, Any]]:
    """Format structured success response with location details."""
    name = loc.get("name", "Campus Location")
    lat = loc.get("latitude", 0.0)
    lon = loc.get("longitude", 0.0)
    desc = loc.get("description", "")
    building = loc.get("building", "")
    floor = loc.get("floor", "")
    room = loc.get("room", "")
    verified = loc.get("coordinates_verified", True)

    details = []
    if building:
        details.append(f"Building: {building}")
    if floor:
        details.append(f"Floor: {floor}")
    if room:
        details.append(f"Room: {room}")

    detail_str = f" ({', '.join(details)})" if details else ""

    # Check if coordinates are valid
    has_coords = bool(lat and lon and lat != 0.0 and lon != 0.0 and verified)

    if has_coords:
        reply = (
            f"📍 **{name}**{detail_str}\n\n"
            f"{desc}\n\n"
            f"Here is the interactive map centered on **{name}** at Maliba Campus. You can zoom and explore surrounding buildings."
        )
    else:
        reply = (
            f"📍 **{name}**{detail_str}\n\n"
            f"{desc}\n\n"
            f"*(Note: GPS coordinates for this location are currently pending field verification by the administration. Interactive map pin is temporarily disabled.)*"
        )

    # Clean location payload for frontend
    location_payload = {
        "name": name,
        "latitude": float(lat) if has_coords else 0.0,
        "longitude": float(lon) if has_coords else 0.0,
        "description": desc,
        "building": building,
        "floor": floor,
        "room": room,
        "category": loc.get("category", "academic"),
        "coordinates_verified": has_coords,
        "aliases": loc.get("aliases", [])
    }

    follow_ups = [
        "Where is the computer lab?",
        "Where is the canteen?",
        "Where is the administrative office?",
        "How can I reach the main gate?"
    ]
    # Filter out current location from follow-ups
    follow_ups = [f for f in follow_ups if name.lower() not in f.lower()][:3]

    response = {
        "status": "success",
        "success": True,
        "type": "location",
        "answer": reply,
        "reply": reply,
        "location": location_payload,
        "follow_up_questions": follow_ups,
        "suggestions": follow_ups,
        "personalized_guidance": "Ask me about any classroom, lab, office, or facility at SRIMCA Maliba Campus."
    }
    return True, response


def _build_not_found_response(question: str) -> Tuple[bool, Dict[str, Any]]:
    """Format helpful response when location question cannot be matched."""
    # List top known landmarks to assist the user
    known = ["Library", "Computer Labs", "Administrative Office", "Canteen", "Faculty Room", "Main Gate", "Auditorium", "Sports Complex"]
    reply = (
        f"I couldn't locate that specific place in the SRIMCA campus database.\n\n"
        f"Available verified campus locations include:\n"
        + "\n".join([f"• **{item}**" for item in known])
        + "\n\nPlease try asking about one of these locations, e.g., *'Where is the library?'* or *'Where is the computer lab?'*."
    )

    response = {
        "status": "success",
        "success": True,
        "type": "location_not_found",
        "answer": reply,
        "reply": reply,
        "location": None,
        "follow_up_questions": [
            "Where is the library?",
            "Where is the computer lab?",
            "Where is the canteen?"
        ],
        "suggestions": [
            "Where is the library?",
            "Where is the computer lab?",
            "Where is the canteen?"
        ],
        "personalized_guidance": "You can ask for locations by name, alias, or landmark."
    }
    return True, response


def seed_default_campus_locations(force: bool = False) -> int:
    """
    Seed verified default campus locations into MongoDB if the collection is empty.
    Avoids duplicate records by checking existence.
    Returns the number of documents inserted.
    """
    try:
        col = get_collection(Collections.CAMPUS_LOCATIONS)
        current_count = col.count_documents({})
        if current_count > 0 and not force:
            print(f"[CampusNav] campus_locations collection already has {current_count} documents. Skipping seed.")
            return 0

        inserted_count = 0
        for loc_data in VERIFIED_DEFAULT_LOCATIONS:
            # Check by unique name
            existing = col.find_one({"name": loc_data["name"]})
            if not existing:
                doc = CampusLocationModel.create_location(
                    name=loc_data["name"],
                    latitude=loc_data["latitude"],
                    longitude=loc_data["longitude"],
                    description=loc_data["description"],
                    aliases=loc_data.get("aliases", []),
                    building=loc_data.get("building", ""),
                    floor=loc_data.get("floor", ""),
                    room=loc_data.get("room", ""),
                    category=loc_data.get("category", "academic"),
                    coordinates_verified=loc_data.get("coordinates_verified", True)
                )
                col.insert_one(doc)
                inserted_count += 1

        print(f"[CampusNav] Successfully seeded {inserted_count} verified campus locations.")
        return inserted_count
    except Exception as e:
        print(f"[CampusNav] Seeding notice: MongoDB unavailable or error: {e}")
        return 0
