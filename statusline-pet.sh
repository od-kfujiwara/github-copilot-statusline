#!/bin/bash
python3 - <<'STATUSLINE_PY'
import json
from pathlib import Path

ANSI_RESET = "\033[0m"
ANSI_DIM = "\033[90m"
ANSI_CYAN = "\033[36m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_MAGENTA = "\033[35m"
ANSI_RED = "\033[31m"

PERCENT_FULL = 100
DEFAULT_QUOTA_FILE = Path.home() / ".copilot" / "premium-quota.json"
ICON_LINES = [
    "╭─╮╭─╮",
    "╰─╯╰─╯",
    "█ ▘▝ █",
    " ▔▔▔▔",
]


# quota情報を読み込み
def load_quota():
    try:
        with open(DEFAULT_QUOTA_FILE, "r", encoding="utf-8") as quota_file:
            return json.load(quota_file)
    except (OSError, json.JSONDecodeError):
        return None


# 使用率に応じてCopilot風アイコンの色を返す
def render_icon(actual_fraction):
    growth_percent = actual_fraction * PERCENT_FULL

    if growth_percent < 10:
        color = ANSI_DIM
    elif growth_percent < 30:
        color = ANSI_CYAN
    elif growth_percent < 55:
        color = ANSI_GREEN
    elif growth_percent < 80:
        color = ANSI_YELLOW
    elif growth_percent < 95:
        color = ANSI_MAGENTA
    else:
        color = ANSI_RED

    return "\n".join(f"{color}{line}{ANSI_RESET}" for line in ICON_LINES)


# quota情報から最終的なステータスライン文字列を作成
def render_statusline(quota):
    total_used = quota.get("usedRequests", 0)
    monthly_limit = quota.get("entitlementRequests")

    if quota.get("isUnlimitedEntitlement", False) or not monthly_limit:
        return "\n".join(f"{ANSI_CYAN}{line}{ANSI_RESET}" for line in ICON_LINES)

    actual_fraction = min(max(total_used / monthly_limit, 0.0), 1.0)
    return render_icon(actual_fraction)


def main():
    quota = load_quota()
    if quota is None:
        print("\n".join(f"{ANSI_DIM}{line}{ANSI_RESET}" for line in ICON_LINES))
        return

    print(render_statusline(quota))


if __name__ == "__main__":
    main()
STATUSLINE_PY
