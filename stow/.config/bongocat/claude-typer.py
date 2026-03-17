#!/usr/bin/env python3
"""
claude-typer — daemon que simula teclas pro BongoCat enquanto o Claude está ativo.

Fluxo:
  - Cria um teclado virtual via uinput chamado "claude-bongo"
  - Fica monitorando /tmp/zion-hive-mind/bongo-active
  - Quando o arquivo existe: manda keypresses (space) a cada ~150ms
  - Quando não existe: fica em idle polling

O udev rule cria /dev/input/claude-bongo como symlink estável pro device.
O bongocat.conf aponta pra esse symlink.
"""

import os
import sys
import time
import signal

SIGNAL_FILE = "/tmp/zion-hive-mind/bongo-active"
KEYPRESS_INTERVAL = 0.15  # segundos entre teclas simuladas


def main():
    try:
        import evdev
        from evdev import UInput, ecodes
    except ImportError:
        print("ERRO: python3-evdev não encontrado", file=sys.stderr, flush=True)
        sys.exit(1)

    capabilities = {
        ecodes.EV_KEY: [ecodes.KEY_SPACE],
    }

    running = True

    def handle_signal(sig, frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    try:
        with UInput(capabilities, name="claude-bongo") as ui:
            print(f"[claude-typer] virtual keyboard: {ui.device.path}", flush=True)

            while running:
                if os.path.exists(SIGNAL_FILE):
                    # Envia keypress (press + release)
                    ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 1)
                    ui.write(ecodes.EV_SYN, ecodes.SYN_REPORT, 0)
                    ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 0)
                    ui.write(ecodes.EV_SYN, ecodes.SYN_REPORT, 0)
                    time.sleep(KEYPRESS_INTERVAL)
                else:
                    time.sleep(0.1)

    except PermissionError:
        print("[claude-typer] ERRO: sem permissão pra /dev/uinput — checar grupo uinput", file=sys.stderr, flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
