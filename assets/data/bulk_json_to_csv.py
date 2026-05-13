import os, json, csv

DATA_DIR = "."  # current folder
MAP_FILE = "section_map.json"
OUT_FILE = "questions_import.csv"

letters = ["A", "B", "C", "D"]

with open(MAP_FILE, "r", encoding="utf-8") as f:
    section_map = json.load(f)

def normalize_opts(opts):
    if not isinstance(opts, list) or len(opts) != 4:
        raise ValueError("Each question must have exactly 4 options")
    return [str(x).strip() for x in opts]

rows = []
for filename, section_id in section_map.items():
    path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing file: {path}")

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError(f"{filename} must be a JSON array")

    for i, q in enumerate(data):
        question_text = (q.get("question") or "").strip()
        opts = normalize_opts(q.get("options"))
        ci = q.get("correctIndex")

        if not question_text:
            raise ValueError(f"{filename} item {i}: missing/empty 'question'")
        if ci not in [0, 1, 2, 3]:
            raise ValueError(f"{filename} item {i}: correctIndex must be 0..3, got {ci}")

        rows.append({
            "section_id": section_id,
            "question_text": question_text,
            "option_a": opts[0],
            "option_b": opts[1],
            "option_c": opts[2],
            "option_d": opts[3],
            "correct_answer": letters[ci],  # 2 -> C (3rd option)
        })

with open(OUT_FILE, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=[
        "section_id","question_text","option_a","option_b","option_c","option_d","correct_answer"
    ])
    w.writeheader()
    w.writerows(rows)

print(f"Wrote {len(rows)} rows to {OUT_FILE}")