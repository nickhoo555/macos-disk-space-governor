---
name: macos-disk-space-governor
description: Help macOS users safely govern scarce internal disk space by auditing storage, separating delete/rebuild/archive candidates, and moving cold data to mounted SMB private-cloud shares or external disks. Use when a user asks to free space on a Mac, investigate what is using storage, archive files off the internal disk, use ncdu or rsync for macOS storage cleanup, or needs persona-specific playbooks for non-technical office workers or technical engineers.
---

# macOS Disk Space Governor

## Core stance

Work like a cautious storage steward, not a cleaner app. Preserve user data first, make the storage map visible, then propose reversible actions with risk labels.

Never delete or move user data without explicit confirmation. Prefer `ncdu -x` for interactive audit and `rsync` dry-runs for archive/copy operations. Prefer `brew` for installing missing command-line tools on macOS.

## Workflow

1. **Identify persona and goal**
   - Office worker: prioritize understandable categories, Finder-safe archive flows, and app-owned libraries.
   - Engineer: include developer caches, build products, package stores, simulators, Docker, and repo artifacts.
   - If unclear, start with a mixed audit and keep commands read-only.

2. **Check tools and storage targets**
   - Prefer installing missing tools with `brew install ncdu rsync`.
   - Confirm external targets are mounted under `/Volumes/...` before archive work.
   - For SMB private cloud, verify the share is mounted and online; do not treat an unmounted share path as a destination.

3. **Audit before action**
   - Use bundled `scripts/triage.sh` for a read-only first pass.
   - Use `ncdu -x "$HOME"` for user-space inspection. For system-wide Data volume inspection, explain Full Disk Access / permission limitations before suggesting elevated scans.
   - Keep `-x` to avoid accidentally crossing into mounted external disks or network shares.

4. **Classify findings**
   - **Delete/rebuild:** caches, build products, package caches, old simulator runtimes, duplicate generated outputs.
   - **Archive:** old downloads, exports, meeting recordings, installers, large project snapshots, media libraries that the app supports moving.
   - **Keep:** active documents, app databases, keychains, Mail/Photos internals, cloud-sync control files, active repos.
   - **Ignore/defer:** permission-denied areas unless the user grants access or the benefit is clear.

5. **Execute safely**
   - For archive moves, use bundled `scripts/rsync_archive.sh` first in dry-run mode, then rerun with `--apply` only after the user confirms.
   - After a successful archive, ask before removing the original. Prefer a Finder/manual delete step for non-technical users.
   - Summarize actual/reasonable estimated reclaimed space and remaining risk.

## Bundled resources

- `scripts/triage.sh`: read-only macOS disk-space triage, tool checks, mount checks, and persona-specific candidate sizes.
- `scripts/rsync_archive.sh`: safer `rsync` wrapper for copying a source folder into a mounted `/Volumes/...` destination; defaults to dry-run and refuses source deletion.
- `references/playbooks.md`: persona playbooks, command patterns, macOS caveats, and reporting templates. Read this before giving a detailed cleanup/archive plan.

## Output expectations

Give users a short plan with:

- Current pressure: internal free space and top offenders.
- Action table: item, type, estimated space, command or app workflow, risk.
- Confirmation gates: exactly what will be copied, moved, or deleted.
- Rollback note: how the user can verify the archive and recover if needed.
