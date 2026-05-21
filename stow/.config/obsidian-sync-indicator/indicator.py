#!/usr/bin/env python3
"""obsidian-sync-indicator — app indicator SNI pro waybar tray"""

import subprocess
import threading
import time
from PIL import Image, ImageDraw
import pystray

POLL = 30  # segundos entre checks

PALETTE = {
    "active":   (155, 89, 182),  # roxo Obsidian
    "error":    (231, 76,  60),  # vermelho
    "failed":   (231, 76,  60),
    "inactive": (99,  110, 114), # cinza
    "unknown":  (99,  110, 114),
}


def _icon(color: tuple, size: int = 64) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = size // 10
    d.ellipse([m, m, size - m, size - m], fill=(*color, 255))
    return img


def _get_state() -> tuple[str, str]:
    try:
        state = subprocess.run(
            ["systemctl", "is-active", "obsidian-sync"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
    except Exception:
        return "unknown", "obsidian-sync: falha ao verificar"

    if state != "active":
        key = state if state in PALETTE else "unknown"
        return key, f"obsidian-sync: {state}"

    try:
        errs = subprocess.run(
            ["journalctl", "-u", "obsidian-sync",
             "--since", "5 min ago", "--no-pager", "-p", "err", "-q"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
    except Exception:
        errs = ""

    if errs:
        return "error", "obsidian-sync: erros recentes"

    return "active", "obsidian-sync: OK"


def _menu(state: str, title: str) -> pystray.Menu:
    def restart(_i, _it):
        subprocess.run(["systemctl", "restart", "obsidian-sync"])

    def logs(_i, _it):
        subprocess.Popen(["alacritty", "-e", "journalctl", "-u", "obsidian-sync", "-f"])

    def quit_(icon, _it):
        icon.stop()

    return pystray.Menu(
        pystray.MenuItem(title, None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Reiniciar serviço", restart),
        pystray.MenuItem("Ver logs", logs),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Fechar indicador", quit_),
    )


def _poll(icon: pystray.Icon) -> None:
    while True:
        time.sleep(POLL)
        state, title = _get_state()
        icon.icon  = _icon(PALETTE.get(state, PALETTE["unknown"]))
        icon.title = title
        icon.menu  = _menu(state, title)


def main() -> None:
    state, title = _get_state()
    icon = pystray.Icon(
        "obsidian-sync",
        _icon(PALETTE.get(state, PALETTE["unknown"])),
        title,
        _menu(state, title),
    )
    threading.Thread(target=_poll, args=(icon,), daemon=True).start()
    icon.run()


if __name__ == "__main__":
    main()
