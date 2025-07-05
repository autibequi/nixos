# Hyprland Configuration Guide

This document outlines the essential keybindings and functionality of this Hyprland setup. The primary modifier key is the **Super** key (also known as the Windows key or Command key).

## Table of Contents
- [Essential Applications](#essential-applications)
- [Keybindings](#keybindings)
  - [Application Launchers](#application-launchers)
  - [Window & Session Management](#window--session-management)
  - [Focus & Layout](#focus--layout)
  - [Workspace Management](#workspace-management)
  - [Hardware & System Control](#hardware--system-control)
- [Core Utilities](#core-utilities)
  - [Screenshots](#screenshots)
  - [Clipboard History](#clipboard-history)
- [Startup Applications](#startup-applications)

## Essential Applications

This configuration defines shortcuts for the following core applications:

| Application | Purpose | Shortcut Variable |
| :--- | :--- | :--- |
| `alacritty` | Terminal Emulator | `$terminal` |
| `dolphin` | File Manager | `$fileManager` |
| `wofi` | Application Launcher | `$menu` |
| `swaylock-effects`| Screen Locker | `$lock` |

## Keybindings

### Application Launchers

| Shortcut | Action |
| :--- | :--- |
| `Super + Q` | Open Terminal (`alacritty`) |
| `Super + E` | Open File Manager (`dolphin`) |
| `Super + R` | Show Application Menu (`wofi`) |
| `Super + L` | Lock the screen |

### Window & Session Management

| Shortcut | Action |
| :--- | :--- |
| `Super + C` | Close the active window |
| `Super + M` | Exit the Hyprland session |
| `Super + F` | Toggle fullscreen for the active window |
| `Super + V` | Toggle floating for the active window |
| `Super + SHIFT + R` | Reload the Hyprland configuration |
| `Super + SHIFT + Arrow Keys`| Move the active window |
| `Super + ALT + Arrow Keys` | Resize the active window |
| `Super + Left Mouse Drag` | Move window with the mouse |
| `Super + Right Mouse Drag`| Resize window with the mouse |

### Focus & Layout

| Shortcut | Action |
| :--- | :--- |
| `Super + Arrow Keys` | Move focus |
| `Super + h/j/k/l` | Move focus (Vim-style) |
| `Super + P` | Toggle pseudotile mode |
| `Super + J` | Toggle split direction (vertical/horizontal) |

### Workspace Management

| Shortcut | Action |
| :--- | :--- |
| `Super + [1-9, 0]` | Switch to the specified workspace (1 to 10) |
| `Super + SHIFT + [1-9, 0]`| Move the active window to the specified workspace |
| `Super + Mouse Scroll` | Cycle through workspaces |
| `Super + S` | Toggle the special workspace (scratchpad) |
| `Super + SHIFT + S` | Move the active window to the special workspace |

### Hardware & System Control

These keybindings use the standard media keys (XF86 keys) on your keyboard.

| Shortcut | Action |
| :--- | :--- |
| `Volume Up Key` | Increase volume |
| `Volume Down Key` | Decrease volume |
| `Mute Key` | Mute/unmute speakers |
| `Mic Mute Key` | Mute/unmute microphone |
| `Play/Pause Key` | Play or pause media (`playerctl`) |
| `Next Track Key` | Go to the next track (`playerctl`) |
| `Previous Track Key` | Go to the previous track (`playerctl`) |
| `Brightness Up Key` | Increase screen brightness |
| `Brightness Down Key`| Decrease screen brightness |

## Core Utilities

### Screenshots

This setup uses `grim` (screenshot tool) and `slurp` (region selector).

| Shortcut | Action |
| :--- | :--- |
| `PrintScreen` | Take a screenshot of a selected region and copy it to the clipboard. |
| `Super + PrintScreen` | Take a screenshot of the entire screen and save it to `~/Pictures/`. |

### Clipboard History

Clipboard history is managed by `cliphist`.

| Shortcut | Action |
| :--- | :--- |
| `Super + V` | Display the clipboard history in a `wofi` menu. Select an item to copy it back to the clipboard. |

## Startup Applications

The following applications are launched automatically when Hyprland starts (`exec-once`):

- **Waybar**: The status bar at the top/bottom of the screen.
- **Polkit Agent**: An authentication agent required for elevated permissions (e.g., when installing software).
- **Sway-idle**: A daemon that locks the screen after 5 minutes of inactivity and turns off the display after 10 minutes.
- **Cliphist**: The daemon that stores clipboard history in the background.