import json
import os
from datetime import datetime

from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise SystemExit(
        "Set env vars SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running."
    )

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_notice(n):
    for k in ["title", "notice_date", "pdf_url"]:
        if k not in n or not str(n[k]).strip():
            raise ValueError(f"Missing required field '{k}' in notice: {n}")

    # validate date format
    datetime.strptime(n["notice_date"], "%Y-%m-%d")


def import_file(path, notice_type):
    items = load_json(path)
    if not isinstance(items, list):
        raise ValueError(f"{path} must contain a JSON array")

    rows = []
    for n in items:
        validate_notice(n)
        rows.append(
            {
                "type": notice_type,
                "title": n["title"],
                "description": n.get("description"),
                "pdf_url": n.get("pdf_url"),
                "notice_date": n["notice_date"],
            }
        )

    if not rows:
        print(f"{path}: no notices to import")
        return

    # Insert. If you want de-duplication, we can add a unique constraint later.
    res = supabase.table("notices").insert(rows).execute()
    print(f"Inserted {len(rows)} notices from {path}")
    return res


if __name__ == "__main__":
    import_file("notices_exam.json", "exam")
    import_file("notices_vacancy.json", "vacancy")