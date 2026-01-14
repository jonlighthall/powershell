# Instructions

**Purpose:** Procedures and standing orders for AI agents working on this project.

---

<!-- ============================================================
     UNIVERSAL INSTRUCTIONS - Applies to all projects
     ============================================================ -->

## Quick Start

1. Read this file for procedures
2. Read `CONTEXT.md` for project facts and decisions
3. Read the relevant topic's `CONTEXT.md` for specific background
4. Read the relevant topic's `INSTRUCTIONS.md` for specific procedures

---

## Context Maintenance (Standing Order)

### Why these files exist

The `.ai/` folder exists **primarily for AI agent utility**—to help future AI sessions onboard quickly without re-asking questions the user has already answered. This is not general documentation; it's working memory for AI agents.

**Implications:**
- Write for an AI audience (your future self, essentially)
- Optimize for fast comprehension at the start of a new session
- Include decisions and their rationale, not just outcomes
- Don't worry about making it "pretty" for humans—clarity and completeness matter more

When the user provides substantial clarifying information, **integrate it into the appropriate `.ai/` file without being asked** (see table below).

### Where to put new information:

| Type of Information | Destination |
|---------------------|-------------|
| Project-wide decisions, facts, history | `.ai/CONTEXT.md` |
| Project-wide procedures, standing orders | `.ai/INSTRUCTIONS.md` |
| Topic-specific history, validation, decisions | `<topic>/CONTEXT.md` |
| Topic-specific procedures, checklists | `<topic>/INSTRUCTIONS.md` |

### When to create a topic folder:

Topic folders add granularity but also overhead. **Default to project-wide files; split when justified.**

**CREATE a topic folder when:**
- The topic has its own lifecycle (can be "completed" independently)
- It has unique decisions or terminology that don't apply elsewhere
- Multiple AI sessions will focus specifically on this topic
- Adding to project-wide files would exceed ~100 lines for this topic alone

**DON'T create a topic folder when:**
- It's a one-off task or short-term work
- The context fits in a few paragraphs
- It shares most decisions with the main project
- You're unsure (start in project-wide files; split later if needed)

**If topic folders already exist:** Use them. Don't consolidate without user direction.

### When to update:

**DO update when:**
- User provides ≥2-3 sentences of explanatory context
- User answers clarifying questions about the project
- User makes a decision that should persist across sessions
- User corrects a misconception (especially if AI-generated)

**DON'T update for:**
- Routine edits, minor corrections
- Conversational exchanges
- Information already documented

### Why this matters:

Context files exist so future AI sessions don't need to re-ask the same questions. If you receive substantial context and don't document it, the next session will be less effective.

### Handling conflicts:

Topic-specific files may override project-wide decisions, but **conflicts must be explicitly documented**.

**If you notice a conflict:**
1. Check if the topic file explicitly notes the override (e.g., "Exception: this component uses X despite project-wide guidance")
2. If the override is documented → follow the topic-specific guidance
3. If the override is NOT documented → ask the user which applies before proceeding

**When creating an intentional override:** Add a note in the topic file explaining what is being overridden and why.

### Handling deprecated/superseded information:

When harvesting context from old chats or updating documentation with newer decisions:

**Newer decisions take precedence**, but preserve the evolution if it's instructive:

```markdown
### [Decision Name]
**Current:** [What we do now]

**Superseded:** Previously we tried [X] but switched because [reason].
(Chat from YYYY-MM-DD)
```

**When to preserve the old approach:**
- It explains *why* we don't do something (prevents re-asking)
- It documents a failed experiment (prevents repeating mistakes)
- It shows the evolution of thinking

**When to simply delete:**
- Trivial or obvious corrections
- Typos/errors with no instructive value
- Exploratory ideas that were never actually tried

**If chronology is unclear:** Ask the user which version is current before overwriting.

### If you cannot write to these files:

Some AI tools have read-only access. If you receive substantial context but cannot update the `.ai/` files, summarize what should be added and ask the user to update the files manually.

---

## General Quality Standards

### Before Editing:
1. Verify you have sufficient context
2. Check terminology against `CONTEXT.md`
3. Use the author's preferred voice (see `CONTEXT.md`)

### After Editing:
1. Verify the edit didn't break anything (compilation, syntax, etc.)
2. Update the relevant `CONTEXT.md` if you made decisions that should persist
3. Check for errors introduced

### When Uncertain:
- Ask clarifying questions before making changes
- Document assumptions in the relevant `CONTEXT.md`
- Prefer minimal changes over extensive rewrites

---

<!-- ============================================================
     PROJECT-SPECIFIC INSTRUCTIONS
     ============================================================ -->

## This Project

### File Organization

- **Root directory:** PowerShell scripts (`.ps1`)
- **`bin/` directory:** Bash/shell equivalents (`.sh`) for WSL/Linux use
- **`Profile.ps1`:** PowerShell profile configuration

### Script Categories

| Category | Examples | Purpose |
|----------|----------|---------|
| Automation | `clicker.ps1`, `wiggler.ps1` | Mouse/keyboard automation, keep-alive |
| CAC/Security | `cac-monitor.ps1` | Smart card monitoring, Outlook management |
| Fortran Formatting | `break-fortran-lines.ps1`, `normalize-fortran-continuations.ps1` | Code formatting tools |
| File Management | `copy_and_rename.ps1`, `rm_dupes.ps1`, `mv2dateDir.ps1` | File operations |
| WSL Integration | `wsl-startup.ps1`, `wsl_shutdown.ps1` | WSL management |
| Setup/Config | `make_links.ps1`, `install_modules.ps1` | Environment setup |

### Code Style

- Use standard PowerShell conventions
- Include descriptive comments for complex logic
- Use `Write-Host` with `-ForegroundColor` for user feedback
- Prefer verbose output during development, with options to reduce verbosity

### Testing

- Scripts are primarily tested manually
- No formal test framework in use
- Test significant changes before committing

### VS Code Tasks

Two build tasks are defined for Fortran formatting:
- `Break and Normalize Fortran (Global)` — Full formatting pass
- `Break Fortran Lines Only (Global)` — Line-breaking only

**Known task configuration issues:**

1. **WSL interference:** If VS Code's default terminal is set to WSL, tasks may fail with:
   ```
   WSL ERROR: execvpe(pwsh.exe) failed: No such file or directory
   ```
   **Fix:** Use `"type": "process"` instead of `"type": "shell"` in tasks.json to bypass shell interpretation.

2. **Paths with spaces:** File paths containing spaces (e.g., OneDrive/SharePoint paths like `US Navy-flankspeed`) require proper quoting in task arguments.

3. **File caching:** VS Code keeps files in memory. After external script modifications:
   - Use **Ctrl+Shift+P → "File: Revert File"** to reload from disk
   - Or close and reopen the file
   - Script writes to temp file first, then moves to destination for atomicity

**Recommended task configuration:**
```json
{
    "label": "Break and Normalize Fortran",
    "type": "process",
    "command": "pwsh.exe",
    "args": [
        "-ExecutionPolicy", "Bypass",
        "-File", "${workspaceFolder}/break-and-normalize.ps1",
        "${file}"
    ],
    "options": {
        "cwd": "${workspaceFolder}"
    }
}
```
