#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: triage.sh [--persona office|engineer|mixed] [--target PATH] [--run-ncdu]

Read-only macOS disk-space triage. It prints volume status, mounted /Volumes targets,
top-level usage for the target, and persona-specific cleanup/archive candidates.

Examples:
  triage.sh --persona office --target "$HOME"
  triage.sh --persona engineer --target "$HOME" --run-ncdu
USAGE
}

PERSONA="mixed"
HOME_DIR="${HOME:-$(printf '%s\n' ~)}"
TARGET="$HOME_DIR"
RUN_NCDU=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --persona)
      PERSONA="${2:-}"; shift 2 ;;
    --target)
      TARGET="${2:-}"; shift 2 ;;
    --run-ncdu)
      RUN_NCDU=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

case "$PERSONA" in
  office|engineer|mixed) ;;
  *) echo "--persona must be office, engineer, or mixed" >&2; exit 2 ;;
esac

if [[ ! -e "$TARGET" ]]; then
  echo "Target does not exist: $TARGET" >&2
  exit 1
fi

have() { command -v "$1" >/dev/null 2>&1; }

size_gb() {
  local path="$1"
  if [[ -e "$path" ]]; then
    du -xg -d 0 "$path" 2>/dev/null | awk '{print $1 " GB\t" $2}' || true
  fi
}

section() { printf '\n== %s ==\n' "$1"; }

section "Tool check"
if have brew; then
  echo "brew: $(command -v brew)"
else
  echo "brew: not found (install Homebrew first if tool installation is needed)"
fi

if have ncdu; then
  echo "ncdu: $(command -v ncdu)"
else
  echo "ncdu: not found. Recommended install: brew install ncdu"
fi

if have rsync; then
  echo "rsync: $(command -v rsync) ($(rsync --version 2>/dev/null | head -1 || echo unknown))"
else
  echo "rsync: not found. Recommended install: brew install rsync"
fi

section "Internal disk / target volumes"
df -h / "$HOME_DIR" "$TARGET" 2>/dev/null | awk 'NR==1 || !seen[$0]++'
if [[ -d /System/Volumes/Data ]]; then
  df -h /System/Volumes/Data 2>/dev/null || true
fi

section "Mounted external / SMB candidates under /Volumes"
if mount | grep -E ' on /Volumes/' >/dev/null 2>&1; then
  mount | grep -E ' on /Volumes/' || true
  df -h /Volumes/* 2>/dev/null || true
else
  echo "No /Volumes mounts detected. Mount the external disk or SMB share before archive work."
fi

section "Top-level usage for target: $TARGET"
echo "Using: du -xg -d 1 <target> (read-only; same filesystem only)"
du -xg -d 1 "$TARGET" 2>/dev/null | sort -nr | head -40 || true

section "Common office archive candidates"
for p in \
  "$HOME_DIR/Downloads" \
  "$HOME_DIR/Desktop" \
  "$HOME_DIR/Documents" \
  "$HOME_DIR/Movies" \
  "$HOME_DIR/Pictures" \
  "$HOME_DIR/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings" \
  "$HOME_DIR/Library/Containers/us.zoom.xos/Data/Documents"; do
  size_gb "$p"
done

if [[ "$PERSONA" == "engineer" || "$PERSONA" == "mixed" ]]; then
  section "Common engineer rebuild/delete candidates"
  for p in \
    "$HOME_DIR/Library/Developer/Xcode/DerivedData" \
    "$HOME_DIR/Library/Developer/Xcode/Archives" \
    "$HOME_DIR/Library/Developer/CoreSimulator/Devices" \
    "$HOME_DIR/Library/Caches/Homebrew" \
    "$HOME_DIR/Library/Caches/pip" \
    "$HOME_DIR/Library/pnpm/store" \
    "$HOME_DIR/.pnpm-store" \
    "$HOME_DIR/.npm" \
    "$HOME_DIR/.yarn" \
    "$HOME_DIR/.gradle/caches" \
    "$HOME_DIR/.cache" \
    "$HOME_DIR/Library/Containers/com.docker.docker"; do
    size_gb "$p"
  done
fi

section "Suggested next scans"
echo "ncdu -x \"$TARGET\""
echo "ncdu -x \"$HOME_DIR/Downloads\""
if [[ "$PERSONA" == "engineer" || "$PERSONA" == "mixed" ]]; then
  echo "ncdu -x \"$HOME_DIR/Library/Developer\""
  echo "docker system df   # if Docker is installed and relevant"
fi

if [[ "$RUN_NCDU" -eq 1 ]]; then
  if have ncdu; then
    section "Running ncdu"
    ncdu -x "$TARGET"
  else
    echo "Cannot run ncdu because it is not installed. Use: brew install ncdu" >&2
    exit 1
  fi
fi
