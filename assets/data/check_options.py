import os
import json

folder = "."

for filename in os.listdir(folder):

    if not filename.endswith(".json"):
        continue

    filepath = os.path.join(folder, filename)

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)

        if not isinstance(data, list):
            print(f"{filename} -> root is not a list")
            continue

        for i, q in enumerate(data):

            opts = q.get("options")

            if not isinstance(opts, list):
                print(
                    f"{filename} | Question #{i + 1} | options is not a list"
                )
                continue

            if len(opts) != 4:
                print(
                    f"{filename} | Question #{i + 1} | "
                    f"has {len(opts)} options"
                )

                print("Question:")
                print(q.get("question"))

                print("Options:")
                print(opts)

                print("-" * 60)

    except Exception as e:
        print(f"{filename} -> ERROR: {e}")