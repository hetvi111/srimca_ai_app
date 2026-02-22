import glob
from config import DATA_DIR

def load_content():
    """Load all text files from data directory."""
    all_text = []
    for f in glob.glob(f"{DATA_DIR}/*.txt"):
        with open(f, "r", encoding="utf-8") as file:
            all_text.append(file.read())
    return "\n".join(all_text)


def load_lines():
    """Load text files as individual lines."""
    all_lines = []
    for f in glob.glob(f"{DATA_DIR}/*.txt"):
        with open(f, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if line:
                    all_lines.append(line)
    return all_lines
