#!/usr/bin/env python3
"""RSS Feed Aggregator — stdlib only.

Fetches RSS 2.0 and Atom feeds, deduplicates, prunes old items,
and generates a compact dashboard for bootstrap.sh.

Usage:
    python3 rss-fetcher.py --config stow/.claude/feeds.md \
                           --data .ephemeral/rss/items.json \
                           --dashboard .ephemeral/rss/dashboard.txt
"""

import argparse
import hashlib
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError

# ── Config parsing ───────────────────────────────────────────────────────────

def parse_feeds_md(path: str) -> tuple[list[dict], dict]:
    """Parse feeds.md → (feeds[], config{})."""
    text = Path(path).read_text()
    feeds = []
    config = {"max_total_items": 50, "item_max_age_days": 7, "dashboard_items": 5}

    # Parse table rows (skip header + separator)
    in_table = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("| URL"):
            in_table = True
            continue
        if in_table and stripped.startswith("|---"):
            continue
        if in_table and stripped.startswith("|"):
            cols = [c.strip() for c in stripped.split("|")[1:-1]]
            if len(cols) >= 3 and cols[0].startswith("http"):
                feeds.append({"url": cols[0], "category": cols[1], "max": int(cols[2])})
        elif in_table and not stripped.startswith("|"):
            in_table = False

    # Parse config section
    for m in re.finditer(r"\*\*(\w+):\*\*\s*(\d+)", text):
        key = m.group(1)
        if key in config:
            config[key] = int(m.group(2))

    return feeds, config


# ── Feed fetching ────────────────────────────────────────────────────────────

def fetch_feed(url: str, timeout: int = 10) -> bytes:
    req = Request(url, headers={"User-Agent": "ClaudinhoRSS/1.0"})
    with urlopen(req, timeout=timeout) as resp:
        return resp.read()


def parse_datetime(s: str) -> datetime:
    """Parse RSS/Atom date string to aware datetime."""
    if not s:
        return datetime.now(timezone.utc)
    # Try RFC 2822 (RSS)
    try:
        return parsedate_to_datetime(s)
    except Exception:
        pass
    # Try ISO 8601 (Atom)
    try:
        # Handle Z suffix
        s = s.replace("Z", "+00:00")
        return datetime.fromisoformat(s)
    except Exception:
        pass
    return datetime.now(timezone.utc)


def parse_feed_xml(data: bytes, category: str, max_items: int) -> list[dict]:
    """Parse RSS 2.0 or Atom feed → list of items."""
    items = []
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        return items

    ns = {"atom": "http://www.w3.org/2005/Atom"}

    # Detect format
    if root.tag == "{http://www.w3.org/2005/Atom}feed" or root.tag == "feed":
        # Atom
        entries = root.findall("atom:entry", ns)
        if not entries:
            entries = root.findall("entry")
        for entry in entries[:max_items]:
            title = (entry.findtext("atom:title", "", ns) or entry.findtext("title", "")).strip()
            link_el = entry.find("atom:link", ns)
            if link_el is None:
                link_el = entry.find("link")
            link = ""
            if link_el is not None:
                link = link_el.get("href", "")
            published = (entry.findtext("atom:published", "", ns)
                        or entry.findtext("atom:updated", "", ns)
                        or entry.findtext("published", "")
                        or entry.findtext("updated", ""))
            if title and link:
                items.append({
                    "title": title,
                    "link": link,
                    "category": category,
                    "published": parse_datetime(published).isoformat(),
                    "id": hashlib.sha256(link.encode()).hexdigest()[:16],
                })
    else:
        # RSS 2.0
        channel = root.find("channel")
        if channel is None:
            channel = root
        for item in channel.findall("item")[:max_items]:
            title = (item.findtext("title") or "").strip()
            link = (item.findtext("link") or "").strip()
            pub_date = item.findtext("pubDate") or ""
            if title and link:
                items.append({
                    "title": title,
                    "link": link,
                    "category": category,
                    "published": parse_datetime(pub_date).isoformat(),
                    "id": hashlib.sha256(link.encode()).hexdigest()[:16],
                })

    return items


# ── Storage ──────────────────────────────────────────────────────────────────

def load_items(path: str) -> list[dict]:
    if os.path.exists(path):
        try:
            with open(path) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return []


def save_items(path: str, items: list[dict]):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(items, f, indent=2, ensure_ascii=False)


# ── Dashboard ────────────────────────────────────────────────────────────────

def fmt_age(dt: datetime) -> str:
    """Format a datetime as relative age string."""
    now = datetime.now(timezone.utc)
    delta = now - dt
    hours = int(delta.total_seconds() / 3600)
    minutes = int(delta.total_seconds() / 60)
    if hours >= 24:
        days = hours // 24
        return f"{days}d ago"
    elif hours > 0:
        return f"{hours}h ago"
    elif minutes > 0:
        return f"{minutes}m ago"
    return "now"


def generate_dashboard(items: list[dict], count: int, path: str):
    """Generate compact dashboard.txt."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Sort by published desc
    sorted_items = sorted(items, key=lambda x: x.get("published", ""), reverse=True)
    lines = []
    max_cat = max((len(i["category"]) for i in sorted_items[:count]), default=4)
    for item in sorted_items[:count]:
        cat = item["category"].ljust(max_cat)
        try:
            pub = datetime.fromisoformat(item["published"])
            if pub.tzinfo is None:
                pub = pub.replace(tzinfo=timezone.utc)
            age = fmt_age(pub)
        except Exception:
            age = "?"
        title = item["title"]
        link = item.get("link", "")
        if len(title) > 60:
            title = title[:57] + "..."
        # OSC 8 hyperlink for clickable titles in terminal
        if link:
            title = f"\033]8;;{link}\a{title}\033]8;;\a"
        lines.append(f"▸ [{cat}] {title} — {age}")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n" if lines else "No items yet.\n")


# ── Vault Kanban ─────────────────────────────────────────────────────────────

def generate_vault_kanban(items: list[dict], path: str):
    """Generate Obsidian kanban board with RSS items grouped by category."""
    os.makedirs(os.path.dirname(path) if os.path.dirname(path) else ".", exist_ok=True)

    # Group by category
    by_cat: dict[str, list[dict]] = {}
    for item in items:
        cat = item.get("category", "other")
        by_cat.setdefault(cat, []).append(item)

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    lines = [
        "---\n",
        "kanban-plugin: board\n",
        "\n---\n\n",
    ]

    # One column per category
    for cat in sorted(by_cat.keys()):
        cat_items = sorted(by_cat[cat], key=lambda x: x.get("published", ""), reverse=True)
        lines.append(f"## {cat}\n\n")
        for item in cat_items:
            title = item["title"]
            link = item.get("link", "")
            try:
                pub = datetime.fromisoformat(item["published"])
                if pub.tzinfo is None:
                    pub = pub.replace(tzinfo=timezone.utc)
                age = fmt_age(pub)
            except Exception:
                age = "?"
            if link:
                lines.append(f"- [ ] [{title}]({link}) `{age}`\n")
            else:
                lines.append(f"- [ ] {title} `{age}`\n")
        lines.append("\n\n")

    # Kanban settings
    lines.append("%% kanban:settings\n```\n{\"kanban-plugin\":\"board\"}\n```\n%%\n")

    with open(path, "w") as f:
        f.writelines(lines)


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="RSS Feed Aggregator")
    parser.add_argument("--config", required=True, help="Path to feeds.md")
    parser.add_argument("--data", required=True, help="Path to items.json")
    parser.add_argument("--dashboard", required=True, help="Path to dashboard.txt")
    parser.add_argument("--vault-kanban", default=None, help="Path to vault kanban.md (Obsidian board)")
    args = parser.parse_args()

    if not os.path.exists(args.config):
        print(f"ERROR: config not found: {args.config}", file=sys.stderr)
        sys.exit(1)

    feeds, config = parse_feeds_md(args.config)
    existing = load_items(args.data)
    existing_ids = {item["id"] for item in existing}

    new_count = 0
    errors = 0

    for feed in feeds:
        try:
            data = fetch_feed(feed["url"])
            items = parse_feed_xml(data, feed["category"], feed["max"])
            for item in items:
                if item["id"] not in existing_ids:
                    existing.append(item)
                    existing_ids.add(item["id"])
                    new_count += 1
        except (URLError, OSError, ET.ParseError) as e:
            print(f"WARN: failed to fetch {feed['url']}: {e}", file=sys.stderr)
            errors += 1

    # Prune old items
    cutoff = datetime.now(timezone.utc) - timedelta(days=config["item_max_age_days"])
    before = len(existing)
    pruned = []
    for item in existing:
        try:
            pub = datetime.fromisoformat(item["published"])
            if pub.tzinfo is None:
                pub = pub.replace(tzinfo=timezone.utc)
            if pub >= cutoff:
                pruned.append(item)
        except Exception:
            pruned.append(item)  # keep unparseable
    existing = pruned
    pruned_count = before - len(existing)

    # Enforce max_total_items (keep newest)
    existing.sort(key=lambda x: x.get("published", ""), reverse=True)
    if len(existing) > config["max_total_items"]:
        existing = existing[:config["max_total_items"]]

    save_items(args.data, existing)
    generate_dashboard(existing, config["dashboard_items"], args.dashboard)

    # Generate vault kanban (Obsidian board)
    if args.vault_kanban:
        generate_vault_kanban(existing, args.vault_kanban)

    # Summary
    print(f"RSS: {len(feeds)} feeds | +{new_count} new | -{pruned_count} pruned | {len(existing)} total | {errors} errors")


if __name__ == "__main__":
    main()
