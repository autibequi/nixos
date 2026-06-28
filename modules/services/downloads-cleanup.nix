{ pkgs, lib, ... }:
let
  user = "pedrinho";
  home = "/home/${user}";

  cleanupScript = pkgs.writeShellScript "home-downloads-cleanup" ''
    set -euo pipefail

    DATE=${pkgs.coreutils}/bin/date
    MV=${pkgs.coreutils}/bin/mv
    FIND=${pkgs.findutils}/bin/find

    readonly HOME_DIR="${home}"
    readonly RETENTION_DAYS=7
    readonly DOWNLOADS="''${HOME_DIR}/Downloads"
    readonly PICTURES="''${HOME_DIR}/Pictures"
    readonly MISPLACED="''${HOME_DIR}/Documents/missplaced"
    readonly SCREENSHOT_DIRS=(
      "''${HOME_DIR}/Pictures/Screenshots"
      "''${HOME_DIR}/Pictures/printscreens"
    )

    is_image() {
      local file="$1"
      local ext="''${file##*.}"
      ext="''${ext,,}"
      case "$ext" in
        jpg | jpeg | png | gif | webp | bmp | svg | heic | heif | avif | tiff | tif | ico)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
    }

    is_partial_download() {
      case "$1" in
        *.crdownload | *.part | *.tmp | *.download | *.partial)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
    }

    safe_move() {
      local src="$1"
      local dest_dir="$2"
      local base dest stem ext stamp

      mkdir -p "$dest_dir"
      base="$(basename "$src")"
      dest="$dest_dir/$base"

      if [[ -e "$dest" ]]; then
        stamp="$("$DATE" +%Y%m%d%H%M%S)"
        if [[ "$base" == *.* && "$base" != .* ]]; then
          stem="''${base%.*}"
          ext=".''${base##*.}"
        else
          stem="$base"
          ext=""
        fi
        dest="$dest_dir/''${stem}-''${stamp}''${ext}"
      fi

      "$MV" -- "$src" "$dest"
    }

    purge_old_screenshots() {
      local dir removed=0
      for dir in "''${SCREENSHOT_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        removed=$(("$FIND" "$dir" -maxdepth 1 -type f -mtime +"$RETENTION_DAYS" -print | wc -l))
        "$FIND" "$dir" -maxdepth 1 -type f -mtime +"$RETENTION_DAYS" -delete
      done
      echo "screenshots removed: $removed"
    }

    tidy_downloads() {
      local entry name moved_img=0 moved_other=0

      [[ -d "$DOWNLOADS" ]] || return 0

      mkdir -p "$PICTURES" "$MISPLACED"

      shopt -s nullglob
      for entry in "$DOWNLOADS"/*; do
        [[ -e "$entry" ]] || continue
        name="$(basename "$entry")"
        is_partial_download "$name" && continue

        if [[ -f "$entry" ]] && is_image "$entry"; then
          safe_move "$entry" "$PICTURES"
          moved_img=$((moved_img + 1))
          echo "moved image: $name → Pictures/"
        else
          safe_move "$entry" "$MISPLACED"
          moved_other=$((moved_other + 1))
          echo "moved file: $name → Documents/missplaced/"
        fi
      done

      echo "downloads tidy: $moved_img images, $moved_other other"
    }

    purge_old_screenshots
    tidy_downloads
  '';
in
{
  systemd.user.services.downloads-cleanup = {
    description = "Limpa screenshots antigos e organiza Downloads (imagens → Pictures, resto → Documents/missplaced)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = cleanupScript;
    };
  };

  systemd.user.timers.downloads-cleanup = {
    description = "Agenda limpeza diária de screenshots e Downloads";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "downloads-cleanup.service";
    };
  };
}
