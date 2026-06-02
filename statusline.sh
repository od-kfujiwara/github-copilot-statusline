#!/bin/bash
python3 - <<'STATUSLINE_PY'
import json
from datetime import date, datetime, time
from pathlib import Path

ANSI_RESET = "\033[0m"
ANSI_DIM = "\033[90m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_RED = "\033[31m"
ANSI_BLACK = "\033[30m"
ANSI_WHITE = "\033[97m"
BG_GREEN = "\033[42m"
BG_YELLOW = "\033[43m"
BG_RED = "\033[41m"

BAR_WIDTH = 12
PERCENT_FULL = 100
WARNING_PACE_RATIO = 1.4
DEFAULT_QUOTA_FILE = Path.home() / ".copilot" / "premium-quota.json"

# quota情報を読み込み
def load_quota():
    try:
        with open(DEFAULT_QUOTA_FILE, "r") as quota_file:
            return json.load(quota_file)
    except (OSError, json.JSONDecodeError):
        return None


# リセット日を基準に現在の請求サイクルを計算
def get_billing_cycle(reset_date):
    cycle_end_date = reset_date
    if cycle_end_date.month == 1:
        cycle_start_date = cycle_end_date.replace(year=cycle_end_date.year - 1, month=12)
    else:
        cycle_start_date = cycle_end_date.replace(month=cycle_end_date.month - 1)

    cycle_start_at = datetime.combine(cycle_start_date, time.min)
    cycle_end_at = datetime.combine(cycle_end_date, time.min)
    now = datetime.now()
    today = date.today()

    return {
        "total_seconds": (cycle_end_at - cycle_start_at).total_seconds(),
        "elapsed_seconds": (now - cycle_start_at).total_seconds(),
        "days_remaining": (cycle_end_date - today).days,
    }


# 現在の利用ペースを計算
def calculate_pacing(remaining_percentage, monthly_limit, total_used, cycle):
    actual_fraction = min((PERCENT_FULL - remaining_percentage) / PERCENT_FULL, 1.0)
    ideal_fraction = 1.0
    if cycle["total_seconds"] > 0:
        ideal_fraction = cycle["elapsed_seconds"] / cycle["total_seconds"]
        ideal_fraction = min(max(ideal_fraction, 0.0), 1.0)
    pace_ratio = (
        actual_fraction / ideal_fraction
        if ideal_fraction > 0
        else (0 if actual_fraction == 0 else 2.0)
    )
    daily_budget = (
        (monthly_limit - total_used) / cycle["days_remaining"]
        if cycle["days_remaining"] > 0
        else 0
    )

    return actual_fraction, pace_ratio, daily_budget


# quota情報から最終的なステータスライン文字列を作成
def render_statusline(quota):
    total_used = quota.get("usedRequests", 0)
    monthly_limit = quota.get("entitlementRequests")

    if quota.get("isUnlimitedEntitlement", False) or not monthly_limit:
        return f"{ANSI_GREEN}⚡ {total_used} reqs (unlimited){ANSI_RESET}"

    reset_date_text = quota.get("resetDate")
    if not reset_date_text:
        return None

    try:
        reset_date = date.fromisoformat(reset_date_text[:10])
    except ValueError:
        return None

    cycle = get_billing_cycle(reset_date)
    remaining_percentage = quota.get("remainingPercentage", 0)
    actual_fraction, pace_ratio, daily_budget = calculate_pacing(
        remaining_percentage,
        monthly_limit,
        total_used,
        cycle,
    )
    used_percentage = actual_fraction * PERCENT_FULL
    filled = min(int(actual_fraction * BAR_WIDTH), BAR_WIDTH)
    usage_bar = "█" * filled + "░" * (BAR_WIDTH - filled)

    if pace_ratio <= 1.0:
        color = ANSI_GREEN
        pace_badge = f"{BG_GREEN}{ANSI_BLACK} CHILL {ANSI_RESET}{color}"
    elif pace_ratio <= WARNING_PACE_RATIO:
        color = ANSI_YELLOW
        pace_badge = f"{BG_YELLOW}{ANSI_BLACK} CAUTION {ANSI_RESET}{color}"
    else:
        color = ANSI_RED
        pace_badge = f"{BG_RED}{ANSI_WHITE} DANGER {ANSI_RESET}{color}"

    return (
        f"{color}⚡ {usage_bar} "
        f"{total_used}/{monthly_limit} ({used_percentage:.1f}%) │ "
        f"{cycle['days_remaining']}d left │ pace guide:{daily_budget:.0f} credits/day │ {pace_badge}"
        f"{ANSI_RESET}"
    )

def main():
    quota = load_quota()
    if quota is None:
        print(f"{ANSI_DIM}⚡ --/-- │ waiting for quota data{ANSI_RESET}")
        return

    statusline = render_statusline(quota)
    if statusline is None:
        print(f"{ANSI_DIM}⚡ --/-- │ waiting for quota data{ANSI_RESET}")
        return

    print(statusline)


if __name__ == "__main__":
    main()
STATUSLINE_PY
