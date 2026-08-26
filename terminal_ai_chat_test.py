import json
import os
import sys
import requests


def usage():
    print(
        "Usage:\n"
        "  python terminal_ai_chat_test.py --mode student --question \"...\"\n"
        "  python terminal_ai_chat_test.py --mode visitor --question \"...\"\n\n"
        "Required environment variables if you don't pass --api-base: \n"
        "  API_BASE_URL (e.g. https://<backend-host>)\n"
        "Optional for student mode: \n"
        "  AUTH_BEARER_TOKEN (JWT, if backend requires it)\n"
        "  USER_ID (Mongo user id string, optional)\n"
        "Examples:\n"
        "  python terminal_ai_chat_test.py --mode student --question \"fees for MCA?\" --api-base https://srimca-lx6ryuw70-2025mca006-5245s-projects.vercel.app\n"
        "  python terminal_ai_chat_test.py --mode visitor --question \"admissions 2026\" --api-base https://srimca-lx6ryuw70-2025mca006-5245s-projects.vercel.app\n"
    )


def normalize_base_url(url: str) -> str:
    url = url.strip()
    if not url:
        return url
    # If user accidentally provided only host (e.g. srimca-lx6ryuw70-2025mca006-5245s-projects.vercel.app)
    # add https:// by default.
    if not (url.startswith("http://") or url.startswith("https://")):
        url = "https://" + url
    return url.rstrip("/")


def main():
    import argparse

    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--mode", choices=["student", "visitor"], required=False)
    parser.add_argument("--question", required=False)
    parser.add_argument("--api-base", required=False, default=os.getenv("API_BASE_URL"))
    parser.add_argument("--token", required=False, default=os.getenv("AUTH_BEARER_TOKEN"))
    parser.add_argument("--user-id", required=False, default=os.getenv("USER_ID"))

    args = parser.parse_args()

    if not args.mode or not args.question:
        usage()
        sys.exit(2)

    api_base = normalize_base_url(args.api_base or "")
    if not api_base:
        print("Missing API base. Provide --api-base or env var API_BASE_URL")
        sys.exit(2)

    endpoint = "/api/ai/ask" if args.mode == "student" else "/api/ai/ask-guest"
    url = api_base + endpoint

    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if args.token:
        headers["Authorization"] = f"Bearer {args.token}"

    payload = {"question": args.question}
    if args.mode == "student" and args.user_id:
        payload["user_id"] = args.user_id

    try:
        resp = requests.post(url, headers=headers, data=json.dumps(payload), timeout=90)
    except Exception as e:
        print(f"Request failed: {e}")
        sys.exit(1)

    # Print debug
    print("\n=== Request ===")
    print("URL:", url)
    print("Mode:", args.mode)
    print("Headers (auth redacted):", {k: ("<redacted>" if k.lower() == "authorization" else v) for k, v in headers.items()})
    print("Payload:", payload)

    print("\n=== Response ===")
    print("HTTP:", resp.status_code)
    try:
        data = resp.json()
        print(json.dumps(data, indent=2))
        ans = data.get("answer")
        if ans:
            print("\n--- Answer ---\n" + str(ans))
    except Exception:
        print(resp.text)


if __name__ == "__main__":
    main()

