#!/usr/bin/env zsh

cal-year() {
    local year=${1:-$(date +%Y)}
    _ncal_highlight "$year"
}

cal-holidays() {
    local input=${1:-$(date +%Y)}
    local requested_year=""
    if [[ -n "$2" ]]; then
        if [[ "$input" =~ ^[0-9]{4}$ ]]; then
            requested_year="$input"
            input="$2"
        else
            echo "Usage: cal-holidays [year|date|holiday] [holiday]"
            return 2
        fi
    fi
    [[ "$input" == "today" ]] && input=$(date +%Y-%m-%d)
    local year cache_dir cache_file

    if [[ -n "$requested_year" ]]; then
        year="$requested_year"
    elif [[ "$input" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$ ]]; then
        year="${input%%-*}"
    elif [[ "$input" =~ ^[0-9]{4}$ ]]; then
        year="$input"
    else
        year=$(date +%Y)
    fi

    cache_dir="$HOME/.dotfiles/.cache/holidays"
    cache_file="$cache_dir/${year}.json"

    mkdir -p "$cache_dir"

    if [[ ! -f "$cache_file" ]]; then
        curl -s "https://api.dagsmart.se/holidays?year=${year}" > "$cache_file"
        if [[ $? -ne 0 || ! -s "$cache_file" ]]; then
            rm -f "$cache_file"
            echo "Failed to fetch holidays for ${year}"
            return 1
        fi
    fi

    if [[ "$input" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$ ]]; then
        python3 - "$cache_file" "$input" <<'PYEOF'
import json, sys
from datetime import date

cache_file, target = sys.argv[1], sys.argv[2]
target_date = date(*map(int, target.split("-")))
with open(cache_file) as f:
    holidays = json.load(f)
matches = [
    h for h in holidays
    if date(*map(int, h["date"].split("-"))) == target_date
]
if matches:
    for h in matches:
        print(f"{target_date.isoformat()}  {h['name']['sv']} ({h['name']['en']})")
else:
    print(f"No holiday on {target_date.isoformat()}")
PYEOF
        return
    fi

    if [[ ! "$input" =~ ^[0-9]{4}$ ]]; then
        python3 - "$cache_file" "$input" <<'PYEOF'
import json, sys

cache_file, query = sys.argv[1], sys.argv[2].casefold()
with open(cache_file) as f:
    holidays = json.load(f)
matches = [
    h for h in holidays
    if any(query in h["name"][language].casefold() for language in ("sv", "en"))
]
if matches:
    for h in matches:
        print(f"{h['date']}  {h['name']['sv']} ({h['name']['en']})")
else:
    print(f"No holiday matching {sys.argv[2]}")
PYEOF
        return
    fi

    _ncal_highlight "$year" "$cache_file"
}

_ncal_highlight() {
    python3 - "$1" "${2:-}" <<'PYEOF'
import os, sys, json, calendar
from datetime import date

year = int(sys.argv[1])
cache_file = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None

today = date.today()

holiday_set = set()
if cache_file:
    with open(cache_file) as f:
        for h in json.load(f):
            parts = h["date"].split("-")
            holiday_set.add((int(parts[1]), int(parts[2])))

RED = "\033[1;31m"
REVERSE = "\033[7m"
DIM = "\033[2m"
RESET = "\033[0m"

requested_links = os.environ.get("CAL_HOLIDAYS_LINKS", "0") == "1"
link_template = os.environ.get(
    "CAL_HOLIDAYS_LINK_TEMPLATE",
    "https://www.google.com/search?q=Sweden+holiday+{date}",
)

safe_scheme = link_template.lower().startswith(("http://", "https://"))
if requested_links and not safe_scheme:
    print(
        "cal-holidays: CAL_HOLIDAYS_LINK_TEMPLATE must use http:// or https://",
        file=sys.stderr,
    )
links_enabled = requested_links and safe_scheme

def osc8_link(text, url):
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"

cal = calendar.Calendar(firstweekday=0)
mnames = calendar.month_name
groups = [[1,2,3,4], [5,6,7,8], [9,10,11,12]]
MONTH_W = 23
GAP = "   "

total_w = 4 * MONTH_W + 3 * len(GAP)
print(f"{year:^{total_w}}")

for group in groups:
    print(GAP.join(f"{mnames[m]:^{MONTH_W}}" for m in group))
    wk_hdr = f"{DIM}Wk{RESET} Mo Tu We Th Fr Sa Su"
    print(GAP.join([wk_hdr] * 4))

    month_data = []
    for m in group:
        rows = []
        for week in cal.monthdayscalendar(year, m):
            wn = None
            for d in week:
                if d != 0:
                    wn = date(year, m, d).isocalendar()[1]
                    break
            rows.append((wn, week, m))
        month_data.append(rows)

    max_rows = max(len(md) for md in month_data)

    for ri in range(max_rows):
        parts = []
        for mi, m in enumerate(group):
            if ri < len(month_data[mi]):
                wn, days, mn = month_data[mi][ri]
                wn_s = f"{DIM}{wn:2d}{RESET}" if wn is not None else "  "
                day_strs = []
                for d in days:
                    if d == 0:
                        day_strs.append("  ")
                    else:
                        ds = f"{d:2d}"
                        is_hol = (mn, d) in holiday_set
                        is_tod = today.year == year and today.month == mn and today.day == d
                        if is_hol and links_enabled:
                            full_date = f"{year:04d}-{mn:02d}-{d:02d}"
                            link_url = link_template.replace("{date}", full_date)
                        if is_hol and is_tod:
                            ds = f"{RED}{REVERSE}{ds}{RESET}"
                        elif is_hol:
                            ds = f"{RED}{ds}{RESET}"
                        elif is_tod:
                            ds = f"{REVERSE}{ds}{RESET}"
                        if is_hol and links_enabled:
                            ds = osc8_link(ds, link_url)
                        day_strs.append(ds)
                parts.append(f"{wn_s} " + " ".join(day_strs))
            else:
                parts.append(" " * MONTH_W)
        print(GAP.join(parts))
    print()
PYEOF
}

holidays() {
    local year=${1:-$(date +%Y)}
    local cache_dir="$HOME/.dotfiles/.cache/holidays"
    local cache_file="$cache_dir/${year}.json"

    mkdir -p "$cache_dir"

    if [[ ! -f "$cache_file" ]]; then
        curl -s "https://api.dagsmart.se/holidays?year=${year}" > "$cache_file"
        if [[ $? -ne 0 || ! -s "$cache_file" ]]; then
            rm -f "$cache_file"
            echo "Failed to fetch holidays for ${year}"
            return 1
        fi
    fi

    local selected
    selected=$(python3 -c "
import json, sys
with open('$cache_file') as f:
    holidays = json.load(f)
for h in sorted(holidays, key=lambda x: x['date']):
    print(f\"{h['date']}  {h['name']['sv']} ({h['name']['en']})\")
" | fzf --prompt="Holiday ($year) > " --header="Select a holiday")

    [[ -z "$selected" ]] && return

    local date="${selected%% *}"
    cal-holidays "$date"
}
