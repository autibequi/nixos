#!/usr/bin/env python3
"""Read scheduler state.json and print formatted recent runs."""
import json, time, sys

def fmt_ago(ts):
    if not ts or ts == 0: return "never"
    diff = int(time.time()) - int(ts)
    if diff < 0: return "just now"
    if diff < 60: return str(diff) + "s ago"
    if diff < 3600: return str(diff // 60) + "min ago"
    if diff < 86400: return str(diff // 3600) + "h ago"
    return str(diff // 86400) + "d ago"

def fmt_dur(s):
    s = int(s)
    if s == 0: return "-"
    if s < 60: return str(s) + "s"
    if s < 3600: return str(s // 60) + "m" + str(s % 60).zfill(2) + "s"
    return str(s // 3600) + "h" + str((s % 3600) // 60) + "m"

try:
    state = json.load(open(sys.argv[1]))
    tasks = state.get("tasks", {})
    if not tasks:
        sys.exit(1)
    lt = state.get("last_tick", "")
    if lt:
        print("  \033[2mlast tick: " + lt + "\033[0m")
    for name, t in sorted(tasks.items(), key=lambda x: x[1].get("last_run", 0), reverse=True)[:10]:
        lr = t.get("last_run", 0)
        st = t.get("last_status", "?")
        avg = t.get("avg_duration_s", 0)
        total = t.get("runs_total", 0)
        failed = t.get("runs_failed", 0)
        ld = t.get("last_duration_s", 0)
        ic = "\033[32m+\033[0m" if st == "ok" else "\033[31mx\033[0m" if st in ("fail", "error", "timeout") else "\033[33m?\033[0m"
        ago = fmt_ago(lr)
        dur = fmt_dur(ld) if ld else fmt_dur(avg)
        fs = "  \033[31m(" + str(failed) + " fails)\033[0m" if failed > 0 else ""
        print("  " + ic + " " + name.ljust(20) + " \033[38;5;214m" + ago.ljust(12) + "\033[0m \033[2m~" + dur + "  x" + str(total) + fs + "\033[0m")
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(1)
except Exception as e:
    print("  \033[2m(erro: " + str(e) + ")\033[0m")
    sys.exit(1)
