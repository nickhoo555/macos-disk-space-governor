# macOS disk-space governance playbooks

## Safety rules

- Treat `~/Library`, app libraries, and cloud-sync folders as app-owned unless there is a known supported workflow.
- Do not manually edit inside `.photoslibrary`, Mail stores, iCloud Drive metadata, Dropbox/OneDrive/Google Drive control folders, Docker disk images, or database directories unless the user explicitly understands the risk.
- Do not use `rm -rf` as a first-line action. Prefer app UI cleanup, package-manager cleanup, or archive + verify + explicit delete.
- Keep `ncdu -x` scoped to the internal path being inspected so it does not count mounted SMB shares or external disks.
- Before archiving to `/Volumes/...`, check `mount`, `df -h`, and destination write access.

## Tool setup

```bash
brew install ncdu rsync
```

Read-only scan examples:

```bash
ncdu -x "$HOME"
ncdu -x ~/Downloads
ncdu -x ~/Documents
```

System-wide scans may require Full Disk Access for Terminal/Codex and can produce permission errors:

```bash
sudo ncdu -x /System/Volumes/Data
```

## Non-technical office worker playbook

Default tone: avoid jargon; map findings to human categories.

Good first targets:

1. `~/Downloads`: installers, ZIPs, exports, duplicate PDFs, old screen recordings.
2. Desktop and Documents: stale project folders, duplicated exports, large media files.
3. Meeting and chat recordings: Zoom, Teams, Tencent Meeting, Feishu/Lark, WeChat files.
4. App exports: Keynote/PPT/PDF/video exports that can be archived.
5. Trash: empty only after confirming there is no recent recovery need.

Usually avoid direct manual cleanup:

- `~/Library/Mail`, `~/Library/Messages`, `~/Library/Application Support`.
- Photos library internals. Move the whole Photos library only with Photos closed and with a known restore plan; avoid SMB for active Photos libraries.
- iCloud Drive, Dropbox, OneDrive, Google Drive internals. Use the app's “remove download / online-only” features when possible.

Recommended office archive flow:

1. Create an archive folder on `/Volumes/<ExternalOrShare>/Mac-Archive/<YYYY>/<Category>/`.
2. Dry-run with `scripts/rsync_archive.sh --source "<folder>" --dest "<archive-root>"`.
3. Apply with `--apply` after user confirms the dry-run list.
4. Verify sample files open from the destination.
5. Only then remove originals manually or with a separately confirmed command.

## Technical engineer playbook

Start with read-only triage, then propose targeted cleanup by ecosystem.

Common rebuild/delete candidates:

- Xcode: `~/Library/Developer/Xcode/DerivedData`, old `Archives`, unavailable simulators/runtimes.
- iOS simulators: `~/Library/Developer/CoreSimulator/Devices` after checking active simulator use.
- Docker Desktop: unused images/containers/volumes and Docker disk image growth; prefer Docker CLI/UI prune commands over deleting disk images.
- Node: per-repo `node_modules`, package-manager stores/caches (`pnpm store`, npm/yarn caches) when rebuildable.
- Java/Android: Gradle caches, Android build outputs and emulator images.
- Python: virtualenvs, `.tox`, `.venv`, pip/uv caches when rebuildable.
- Rust/Go: `target`, module/build caches where rebuildable.
- Homebrew: old downloads and caches; prefer `brew cleanup` and `brew autoremove` after checking.

Useful engineer commands after audit, only when appropriate:

```bash
brew cleanup --dry-run
brew cleanup
xcrun simctl delete unavailable
# Docker examples: inspect first, prune only with user confirmation
docker system df
docker system prune
```

For repo trees, find large generated directories before deleting:

```bash
find "$HOME" -maxdepth 6 -name node_modules -type d -prune 2>/dev/null
find "$HOME" -maxdepth 6 \( -name .venv -o -name target -o -name build -o -name dist \) -type d -prune 2>/dev/null
```

## External storage guidance

### External disk

- Prefer APFS for Mac-only archive because it preserves macOS metadata better.
- Use exFAT only for cross-platform exchange; warn about metadata/permission limitations.
- Keep at least one additional backup if the external disk becomes the only copy.

### SMB private cloud

- Confirm it is mounted under `/Volumes/<share>` and `df -h /Volumes/<share>` shows the network filesystem.
- Use archives for cold files; avoid live app libraries, active source trees with many small files, virtual machines, and databases on SMB unless the user accepts performance and locking risks.
- Network copies can be interrupted; use `rsync` so reruns resume/repair the archive.

## Reporting template

```markdown
## Disk-space plan

Internal disk: <free>/<total> free. Main pressure: <summary>.

| Priority | Item | Type | Est. space | Action | Risk |
|---|---|---:|---:|---|---|
| 1 | <path/category> | Archive/Delete/Rebuild | <size> | <command or app workflow> | Low/Med/High |

Confirmation needed before destructive steps:
1. <copy/apply command>
2. <delete/manual removal step, if any>

Verification:
- Open 3 sample archived files from the destination.
- Rerun `du`/`ncdu` or `df -h` to confirm reclaimed space.
```
