---
name: hyprland-config
description: Use when the user asks about Hyprland in any way - editing hyprland.conf, window rules, keybindings, workspace config, monitors, animations, decorations, exec-once, plugins, hyprlock, hypridle, waybar, or any file in stow/.config/hypr/. Also use for installing, troubleshooting, or changing the Hyprland NixOS module
---

# Hyprland Configuration & Installation

## Overview

Installing Hyprland on NixOS involves 3 distinct layers: **NixOS module**, **dotfile configs**, and **session runtime**. Each layer must be validated before moving to the next.

This skill ensures you don't skip critical validation steps and provides systematic troubleshooting when the session fails to start.

## Architecture: 3 Layers

```
Layer 1: NixOS Module (modules/hyprland.nix)
  ↓ (defines packages, UWSM, services)
Layer 2: Dotfile Configs (stow/.config/hypr/*.conf)
  ↓ (deployed via stow)
Layer 3: Session Runtime (UWSM → Hyprland process)
  ↓ (validates everything works end-to-end)
```

Each layer can fail independently. Always validate in order.

## 3-Step Checklist

### 1. Validate NixOS Module Layer

**Check: Is hyprland module imported?**
```bash
grep "hyprland" configuration.nix
# Should show: import ./modules/hyprland.nix (not commented)
```

**Check: Are key packages present?**
```bash
nix shell --impure -c which hyprlock waybar hypridle hyprctl
# If any fail, rebuild is needed
```

**Check: Is UWSM configured correctly?**
```bash
cat modules/hyprland.nix | grep -A 3 "programs.uwsm"
# Should show: withUWSM = true; and UWSM package configured
```

**Check: Are plugins enabled/disabled intentionally?**
- Open `modules/hyprland.nix`
- Review `hypr-plugin-dir` section
- Commented-out plugins are intentional (easy to re-enable)
- Uncomment plugins only if you need them

**Decision point:**
- ✅ All checks pass → Move to Layer 2
- ❌ Any check fails → Run `sudo nixos-rebuild switch --flake .#nomad` and re-check

### 2. Validate Dotfile Config Layer

**Check: Do all required config files exist?**
```bash
ls -la stow/.config/hypr/
```

Required files:
- `hyprland.conf` (main config, imports others)
- `hypridle.conf` (idle/sleep behavior)
- `hyprlock.conf` (lock screen)
- `workspace.conf` (workspace layout)
- `application.conf` (app-specific window rules)
- `windowrules.conf` (window rules)
- `systemtools.conf` (system shortcuts)

**Check: Does hyprland.conf import all sub-configs correctly?**
```bash
grep "^source = " stow/.config/hypr/hyprland.conf
# Should show imports for: monitors, windowrules, application, workspace, special-workspaces, plugins
# Files must exist before importing
```

**Check: Is config syntax valid?**
```bash
nix shell --impure -c hyprls lint stow/.config/hypr/hyprland.conf
# Report any syntax errors before deploying
```

**Check: Are dotfiles symlinked into ~?**
```bash
ls -la ~/.config/hypr/ 2>/dev/null
# Should show symlinks pointing to stow/ directory
# If directory doesn't exist or files are copies, run stow deploy
```

**Decision point:**
- ✅ All files exist, syntax valid, symlinks in place → Move to Layer 3
- ❌ Syntax errors → Fix in `stow/.config/hypr/*.conf` and re-validate
- ❌ Symlinks missing → Run `stow -d ~/nixos/stow -t ~ .`

### 3. Validate Session Runtime Layer

**Check: Start Hyprland and verify session initializes**
```bash
# Log out from current session
# At login screen: select "Hyprland (UWSM)" session
# If session doesn't appear, try: UWSM_SESSION=hyprland uwsm start
```

**Check: Are startup services launching?**
After Hyprland starts, open terminal and verify:
```bash
pgrep waybar && echo "✅ waybar running"
pgrep hypridle && echo "✅ hypridle running"
pgrep swaync && echo "✅ notifications running"
```

**Check: Can you interact with core features?**
- ✅ Open terminal (usually Super+Enter)
- ✅ Launch app menu (Super+Space or configured launcher)
- ✅ Switch workspaces (Super+1-9)
- ✅ See wallpaper (swww-daemon should display it)

**If session fails to start:**

**Problem: "No Hyprland session available"**
- Check: `systemctl status uwsm` (should show active)
- Check: UWSM package is from flake (not nixpkgs stable)
- Action: Run `sudo nixos-rebuild switch --flake .#nomad` again

**Problem: "Session starts but crashes immediately"**
- Check: System journal for errors: `journalctl -xe`
- Check: Hyprland config syntax: `hyprls lint stow/.config/hypr/hyprland.conf`
- Check: hyprland.conf can load all imported files (verify they exist)
- Action: Comment out problematic `source =` lines until session is stable

**Problem: "Waybar/hypridle/swaync not starting"**
- Check: Are services defined in hyprland.nix? (they should be)
- Check: Can you start manually? `waybar &` (to test)
- Action: Check system journal: `journalctl -u waybar -n 50`

**Problem: "Plugins not loading"**
- Check: Are plugins uncommented in hyprland.nix? (most are commented by default)
- Check: Can you load plugin in hyprland.conf? `plugin = /path/to/plugin.so`
- Action: For disabled plugins, this is intentional—only enable if needed

## Deployment Order

When making changes, always follow this order:

1. **Edit NixOS module** (e.g., enable a plugin)
2. **Run rebuild**: `sudo nixos-rebuild switch --flake .#nomad`
3. **Edit dotfiles** (e.g., hyprland.conf keybinds)
4. **Redeploy dotfiles**: `stow -d ~/nixos/stow -t ~ .`
5. **Test session**: Log out and back into Hyprland
6. **Verify startup**: Check `pgrep waybar`, `pgrep hypridle`, etc.

## Quick Reference: Essential Commands

| Task | Command |
|------|---------|
| Apply NixOS changes | `sudo nixos-rebuild switch --flake .#nomad` |
| Validate config syntax | `nix shell --impure -c hyprls lint stow/.config/hypr/hyprland.conf` |
| Deploy dotfiles | `stow -d ~/nixos/stow -t ~ .` |
| Check running services | `pgrep waybar && pgrep hypridle && pgrep swaync` |
| View Hyprland logs | `journalctl -xe --grep=hypr` |
| Reload Hyprland config | `hyprctl reload` (while in session) |
| Test wallpaper | `swww query` (should show active wallpaper) |

## Red Flags - Rationalizations to Avoid

These thoughts mean STOP - you're about to skip validation:

| Rationalization | Reality |
|-----------------|---------|
| "I manually checked Layer 1, it's fine" | Manual checks miss edge cases. Use automated checks. |
| "Layer 2 and 3 are more important" | Layer 1 failures break everything. Validate in order. |
| "I'll rebuild later if Layer 2 fails" | Rebuilding after deployment wastes time. Check first. |
| "The session will tell me what's wrong" | Silent crashes make debugging harder. Validate before starting. |
| "Plugins don't matter for basic setup" | Correct—leave them commented. But verify intentionally. |
| "Stow will handle symlinks automatically" | Stow only creates links if configs exist. Check Layer 2 first. |
| "Time is short, I'll skip Layer 1" | Skipping validation takes longer when things break. Always validate. |
| "The config looks right, no need to validate" | Visual inspection ≠ validation. Always use `hyprls lint`. |

**All of these mean: Stop, go back, validate per the skill. No exceptions.**

## Common Mistakes

**❌ Deploying dotfiles before rebuilding NixOS**
- Packages might not be installed yet
- Always rebuild first, then stow

**❌ Editing hyprland.conf without validating syntax**
- Hyprland crashes silently on syntax errors
- Always use `hyprls lint` before reloading

**❌ Assuming plugins work automatically**
- Plugins in hyprland.nix are mostly commented (intentional)
- Only enable plugins you understand and want to use
- Uncomment slowly, test after each change

**❌ Skipping UWSM session selection at login**
- If Hyprland doesn't appear, you may need to manually select it
- Or run: `UWSM_SESSION=hyprland uwsm start` from TTY

**❌ Trying to start Hyprland directly without UWSM**
- UWSM handles dbus, session variables, and cleanup
- Always use UWSM to start (either via session selection or uwsm command)

## When to Enable Plugins

Plugins in `modules/hyprland.nix` are disabled by default:
- `hyprexpo` — workspace overview (nice but optional)
- `hypr-dynamic-cursors` — cursor animation (nice but optional)
- `hyprfocus` — window focus indicator (nice but optional)
- `hyprtrails` — window movement trails (visual only)
- `hyprspace` — workspace switching effects (visual only)

**Only uncomment if:**
1. You understand what the plugin does
2. You've verified it's compatible with your Hyprland version
3. You're willing to troubleshoot if it breaks the session

Recommended approach: Start with core Hyprland (no plugins), add one at a time.
