# Context

**Purpose:** Facts, decisions, and history for AI agents working on this project.

---

<!-- ============================================================
     UNIVERSAL CONTEXT - Applies to all projects
     ============================================================ -->

## Author

**Name:** Jon Lighthall
**GitHub:** jonlighthall

**Affiliation:** Personal project (not work-related)

**Primary tools:**
- PowerShell (Windows)
- Bash/Shell (WSL/Linux)
- VS Code
- Git

**General preferences:**
- Impersonal voice for expository writing
- Mathematical "we" acceptable in derivations ("we substitute...", "we obtain...")
- Avoid editorial "we" ("we believe...", "we recommend...")
- Prefer minimal changes over extensive rewrites

**Writing style:**
- Practical, concise comments
- **Target audience:** Developer (self) and occasional collaborators
- **Level of detail:** Sufficient for future reference

**What NOT to do:**
- **No meta-commentary:** Don't create summary markdown files after edits. If context is worth preserving, put it in `.ai/` files.
- **No hyper-literal headers:** If asked to "add a clarifying statement," don't create a section titled "Clarifying Statement." Integrate naturally.
- **No AI self-narration:** Don't describe what you're doing in the document itself. Just do it.

---

<!-- ============================================================
     PROJECT-SPECIFIC CONTEXT
     ============================================================ -->

## This Project

### Overview

A personal collection of PowerShell utility scripts for productivity and system automation. Some scripts were written as learning exercises; others solve specific automation problems. Includes companion Bash scripts in `bin/` for cross-platform (WSL) compatibility.

**Notable:** The clicker/wiggler scripts have seen wide adoption and propagation at various institutions.

### Key Scripts

| Script | Purpose |
|--------|---------|
| `cac-monitor.ps1` | Monitors CAC smart card reader, prompts to close Outlook when card is removed, auto-closes after idle timeout |
| `clicker.ps1` / `wiggler.ps1` | Mouse automation to prevent screen lock/idle |
| `break-fortran-lines.ps1` | Breaks long Fortran lines at appropriate points |
| `normalize-fortran-continuations.ps1` | Normalizes Fortran continuation markers |
| `Profile.ps1` | PowerShell profile with environment setup |

### CAC Monitor (`cac-monitor.ps1`)

**Purpose:** Security-conscious Outlook management based on CAC card presence.

**Key decisions:**
- Uses PC/SC (Smart Card) API via P/Invoke for card detection
- Graceful Outlook close via COM automation; force-kill disabled by default (`$AllowForceKill = $false`)
- 120-minute idle threshold for auto-close when card is removed
- Idle timer active from startup if card is initially removed (not just during runtime)
- Progress-based status updates at 25%, 50%, 75% of threshold (3 messages before auto-close prompt)
- Reader name parsing uses explicit array return (`,$result`) to prevent PowerShell string iteration
- STA mode required for Windows Forms dialogs

**Output format:**
- Timestamps: `[yyyy-MM-dd HH:mm:ss]`
- Card state: `*** CARD INSERTED ***` (green) / `*** CARD REMOVED ***` (red)
- Idle progress: `Idle: X min | Auto-close in: Y min` (dark gray, at 25%/50%/75%)
- Threshold warning: `Idle threshold reached: X minutes idle` (yellow)

### Cross-Platform Strategy

- PowerShell scripts (`.ps1`) are the primary implementation
- Bash equivalents in `bin/` provide WSL/Linux compatibility
- `make_links.ps1` / `make_links.sh` set up symlinks for easy access

### License

MIT License (Copyright 2020 Jon Lighthall)

---

## History & Decisions

### 2026-01-13: CAC Monitor Idle Timer Fixes
- Fixed reader name parsing: `Get-ReaderNames` now returns proper array with `,$result` syntax
- Added `@()` wrapping in foreach loops to prevent single-reader string iteration
- Idle timer now monitors from initial "card removed" state (edge case: computer restart with card out)
- Changed from time-based intervals to progress-based thresholds (25%, 50%, 75%)
- Moved configuration variables before initial state check so `$idleThresholdMinutes` is defined
- Removed blank line before "Idle threshold reached" message

---

## Superseded Decisions

### Idle Timer Update Intervals
**Current:** Progress-based thresholds at 25%, 50%, 75% of idle threshold (exactly 3 progress messages before auto-close prompt).

**Superseded:** Previously tried time-based intervals (`$statusUpdateInterval = threshold/4`) but this produced inconsistent message counts depending on timing. Also tried `[math]::Max(0.5, ...)` for short thresholds, but still resulted in 6 messages instead of the expected 4.
(Chat from 2025-12-08 / 2026-01-13)
