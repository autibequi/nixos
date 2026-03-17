---
name: nixos
description: Use when adding packages, changing NixOS options, editing modules, or troubleshooting build failures - searches packages/options via MCP-NixOS, edits modules, runs nh os test, and iterates on errors
---

# NixOS Configuration Management

## Overview

This skill manages the full lifecycle of NixOS configuration changes: search for packages/options, edit the correct module, build-test, and iterate on errors until the build passes.

## Prerequisites

- MCP server `mcp-nixos` must be running (configured in `.mcp.json`)
- `nh` must be installed (provides `nh os test`, `nh search`)

## Workflow

```
User requests a change
  -> Search package/option (MCP-NixOS)
  -> Identify correct module to edit
  -> Edit module
  -> nh os test .
  -> Pass? -> Done
  -> Fail? -> Classify error -> Fix -> nh os test . (loop, max 3 auto-retries)
```

## Step 1: Search with MCP-NixOS

Use the `mcp__nixos__nix` tool to find packages and options.

**Finding a package:**
```
mcp__nixos__nix(action: "search", type: "packages", query: "firefox")
```

**Finding a NixOS option:**
```
mcp__nixos__nix(action: "search", type: "options", query: "services.openssh")
```

**Getting detailed info on a package:**
```
mcp__nixos__nix(action: "info", type: "packages", query: "nixpkgs#firefox")
```

**Getting detailed info on an option:**
```
mcp__nixos__nix(action: "info", type: "options", query: "services.openssh.enable")
```

**Home Manager options:**
```
mcp__nixos__nix(action: "search", type: "home-manager-options", query: "programs.git")
```

If MCP is unavailable, fall back to `nh search <query>`.

## Step 2: Identify the Correct Module

This repo has a specific structure. Match the change to the right file:

| Change type | File |
|---|---|
| System package (available to all users) | `modules/core/packages.nix` |
| User program with config options | `modules/core/programs.nix` |
| Systemd service / daemon | `modules/core/services.nix` |
| Font | `modules/core/fonts.nix` |
| Shell alias / env var / starship | `modules/core/shell.nix` |
| Kernel param / sysctl | `modules/core/kernel.nix` |
| Nix settings (substituters, experimental features) | `modules/core/nix.nix` |
| Hibernate / resume | `modules/core/hibernate.nix` |
| NVIDIA GPU config | `modules/nvidia.nix` |
| ASUS hardware (asusctl, supergfxctl) | `modules/asus.nix` |
| Bluetooth | `modules/bluetooth.nix` |
| Hyprland compositor | `modules/hyprland.nix` |
| Steam / gaming | `modules/steam.nix` |
| AI tools (ComfyUI, SD) | `modules/ai.nix` |
| Containers (podman) | `modules/podman.nix` |
| Virtualization (libvirt, QEMU) | `modules/virt.nix` |
| Work-related tools | `modules/work.nix` |
| Login greeter | `modules/greetd.nix` |
| Boot splash | `modules/plymouth.nix` |
| Logitech mouse | `modules/logiops.nix` |

**New feature module:** If the change doesn't fit any existing module, create `modules/<name>.nix` and add it to `configuration.nix`.

**Dotfile configs** (Hyprland keybinds, Waybar layout, Zed settings, etc.) live in `stow/.config/` and are deployed with `stow -d ~/nixos/stow -t ~ .`, NOT managed by NixOS modules.

**Unstable packages:** To use a package from the unstable channel, use `unstable.pkgs.<name>` or `unstable.<name>`. The `unstable` arg is available in all modules via `specialArgs`.

## Step 3: Edit the Module

Read the target module first. Follow existing patterns in the file (indentation, style, grouping). Make minimal changes.

## Step 4: Build and Test

Run the build test:

```bash
nh os test .
```

This builds the configuration and activates it temporarily (does not persist across reboots). It is safe to run repeatedly.

**Do NOT run `nh os switch .` or `sudo nixos-rebuild switch` unless the user explicitly asks.** `test` is for validation; `switch` makes it permanent.

## Step 5: Error Handling (Hybrid Loop)

When `nh os test .` fails, read the error output and classify it:

### Auto-fix errors (correct and re-test without asking, max 3 attempts):

| Error pattern | Fix |
|---|---|
| `error: undefined variable 'pkgName'` | Package name is wrong. Search MCP for correct name. |
| `error: attribute 'x' missing` | Wrong attribute path. Check with `mcp__nixos__nix info`. |
| `error: syntax error, unexpected X` | Nix syntax error (missing semicolon, brace, etc.). Fix syntax. |
| `error: The option 'x' does not exist` | Wrong option name. Search MCP for correct option. |
| `error: duplicate definition` | Option set twice. Remove the duplicate. |
| `is not available on the requested hostPlatform` | Package not available for x86_64-linux. Remove or find alternative. |

### Ask-before-fix errors (propose fix and wait for user confirmation):

| Error pattern | Action |
|---|---|
| `error: collision between` | Package conflict. Show both packages and ask which to keep. |
| `error: infinite recursion` | Structural issue. Explain the cycle and propose a fix. |
| `error: evaluation aborted` with `assert` | An assertion failed. Explain what condition isn't met. |
| Build succeeds but service fails at activation | Show journal output, propose config change. |
| Any error you don't recognize | Show the full error and ask for guidance. |

### Loop rules:

1. Max **3 automatic retries** for simple errors
2. After 3 failures, **stop and show the full error** to the user
3. Never auto-fix the same error twice (if the fix didn't work, escalate)
4. On each retry, show a one-line summary of what was fixed

## Quick Reference

| Task | Command |
|---|---|
| Test build (safe, temporary) | `nh os test .` |
| Apply permanently | `nh os switch .` (only when user asks) |
| Search packages | `mcp__nixos__nix search packages <query>` |
| Search options | `mcp__nixos__nix search options <query>` |
| Package info | `mcp__nixos__nix info packages <query>` |
| Deploy dotfiles | `stow -d ~/nixos/stow -t ~ .` |
| Update flake inputs | `nix --extra-experimental-features 'nix-command flakes' flake update` |
