# macOS Disk Space Governor

A community-installable Agent Skill for safely auditing and governing scarce macOS internal disk space.

## Install

Install the skill with the Skills CLI:

```bash
npx skills add <owner>/macos-disk-space-governor --skill macos-disk-space-governor
```

For a local checkout:

```bash
npx skills add . --skill macos-disk-space-governor
```

## What it supports

- Non-technical office users: Downloads, Documents, meeting recordings, app exports, and safe archive workflows.
- Technical engineers: developer caches, build outputs, package stores, simulators, Docker, and repo-generated artifacts.
- External storage targets: mounted SMB private-cloud shares and external disks under `/Volumes/...`.
- Tools: `ncdu -x` for same-filesystem inspection and `rsync` for dry-run-first archive copies.

## Repository structure

```text
skills/
└── macos-disk-space-governor/
    ├── SKILL.md
    ├── agents/openai.yaml
    ├── references/playbooks.md
    └── scripts/
        ├── triage.sh
        └── rsync_archive.sh
```

## Safety stance

The skill defaults to read-only audit, dry-run archive commands, and explicit confirmation before destructive steps.
