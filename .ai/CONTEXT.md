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

**Productivity guardrail:**

To support efficient workflows, AI agents should monitor for patterns that may indicate diminishing returns or misalignment with project goals.

**Observe for:**
- Repeated iterations on low-impact details (e.g., cosmetic formatting that doesn't affect functionality or clarity)
- Lines of inquiry that appear tangential to stated goals
- Scope creep where effort exceeds proportional value

**If misalignment is likely:** Gently note it with phrases like *"This might be venturing into diminishing returns—does it align with our goals?"* Always defer to the user; do not refuse or block actions.

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

### Fortran Line Breaking (`break-fortran-lines.ps1`)

**Purpose:** Wrap Fortran 77 fixed-form lines to a maximum column (default 72) with proper continuation.

**Key decisions:**
- **Prioritized break points:** Commas > spaces > operators (`+`, `-`, `*`, `/`, `)`, `]`)
- **No commas at line start:** Lines should end with commas; continuation lines should not start with commas
- **Parenthesis protection:** Avoids breaking inside parentheses (e.g., `rb(mr)`, `r1(mz,mp)`)
- **Smart fallback:** When no ideal break points exist, finds word boundaries (alphanumeric/non-alphanumeric transitions)
- **Continuation character:** Default `>` in column 6
- **Smart indentation:** Continuation lines indent baseIndent + 3 spaces
- **Inline comment detection:** Lines with inline comments (`!`) are not broken

**Fixed-form rules applied:**
- Columns 1-5: label or blanks
- Column 6: continuation character (non-blank indicates continuation)
- Columns 7-72: statement text

**Known issues:**
- Script works on isolated lines but may fail on full files in certain contexts (debugging ongoing)
- VS Code task configuration requires special handling (see INSTRUCTIONS.md)

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

### 2025-01 — Fortran Line Breaking Enhancements
- Enhanced `Find-SafeBreakIndex` with parenthesis depth tracking
- Added prioritized break point logic: commas > spaces > operators
- Lines now end with commas; continuation lines don't start with commas
- Added word boundary fallback for lines with no ideal break points
- Added verbose output for debugging file operations

---

## Superseded Decisions

### Idle Timer Update Intervals
**Current:** Progress-based thresholds at 25%, 50%, 75% of idle threshold (exactly 3 progress messages before auto-close prompt).

**Superseded:** Previously tried time-based intervals (`$statusUpdateInterval = threshold/4`) but this produced inconsistent message counts depending on timing. Also tried `[math]::Max(0.5, ...)` for short thresholds, but still resulted in 6 messages instead of the expected 4.
(Chat from 2025-12-08 / 2026-01-13)
