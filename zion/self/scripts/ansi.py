#!/usr/bin/env python3
"""scripts/ansi.py — ANSI and unicode utilities for shell scripts.

Usage from shell:
  python3 scripts/ansi.py strip "hello \033[32mworld\033[0m"
  python3 scripts/ansi.py vlen "hello \033[32mworld\033[0m"
  python3 scripts/ansi.py calc "3.14 * 2"

Usage from Python:
  from ansi import strip_ansi, visual_len, calc
"""

import re
import sys
import unicodedata

_ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')


def strip_ansi(text: str) -> str:
    """Remove all ANSI escape sequences from text."""
    return _ANSI_RE.sub('', text)


def visual_len(text: str) -> int:
    """Length of text as displayed in terminal (handles ANSI + wide chars)."""
    clean = strip_ansi(text)
    return sum(
        2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1
        for c in clean
    )


def calc(expression: str) -> str:
    """Evaluate a math expression and return result as string."""
    try:
        result = eval(expression, {"__builtins__": {}}, {})  # noqa: S307
        if isinstance(result, float) and result.is_integer():
            return str(int(result))
        return str(result)
    except Exception:
        return "0"


def pad_to(text: str, width: int, fillchar: str = ' ') -> str:
    """Pad text to visual width, accounting for ANSI codes and wide chars."""
    current = visual_len(text)
    padding = max(0, width - current)
    return text + fillchar * padding


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: ansi.py <command> [args...]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == 'strip':
        text = sys.argv[2] if len(sys.argv) > 2 else sys.stdin.read()
        print(strip_ansi(text), end='')

    elif cmd == 'vlen':
        text = sys.argv[2] if len(sys.argv) > 2 else sys.stdin.read()
        print(visual_len(text))

    elif cmd == 'calc':
        expr = ' '.join(sys.argv[2:])
        print(calc(expr))

    elif cmd == 'pad':
        text = sys.argv[2]
        width = int(sys.argv[3])
        fillchar = sys.argv[4] if len(sys.argv) > 4 else ' '
        print(pad_to(text, width, fillchar), end='')

    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)
