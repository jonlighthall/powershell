# AGENTS.md

## For Humans

You've stumbled into the staff entrance.

This file exists because AI coding assistants need a consistent place to look for instructions. Think of it as the "Employees Only" sign that actually has useful information behind it—just not for you.

The documentation you want is in the main README (if one exists) or in the scripts themselves. This file just points the robots to their briefing materials in the `.ai/` folder.

Feel free to read it. Just don't edit it unless you enjoy confusing machines.

*—Building Management*

---

## For AI Agents

This repository uses a structured `.ai/` directory for context and instructions.
All AI agents should prioritize the following files for project-specific guidance:

1. **[.ai/INSTRUCTIONS.md](.ai/INSTRUCTIONS.md)** — Standing orders and procedures
2. **[.ai/CONTEXT.md](.ai/CONTEXT.md)** — Project facts, history, and decisions
3. **[.ai/README.md](.ai/README.md)** — AI orientation

**Directive:** Do not rely solely on file-level comments. Always reference the `.ai/` folder for authoritative procedures and constraints.

---

## Quick Reference

**Project:** Personal PowerShell utility scripts for productivity and automation.

**Key directories:**
- `/` — PowerShell scripts (`.ps1`)
- `/bin/` — Bash equivalents for WSL/Linux (`.sh`)
- `/.ai/` — AI context files

**Notable scripts:**
- `cac-monitor.ps1` — CAC smart card monitoring, Outlook auto-close
- `clicker.ps1`, `wiggler.ps1` — Keep-alive automation (widely adopted)
- `break-fortran-lines.ps1` — Fortran code formatting

**Author:** Jon Lighthall (personal project, no affiliation)

---

*This file is the universal entry point. For detailed context, always defer to `.ai/`.*
