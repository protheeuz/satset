# Git Commit Guidelines

Commit messages must be concise, professional, and follow conventional commit format.

---

## Format

```bash
type: brief description (max 50 characters)
```

**Rules:**

- Max 50 characters total
- Imperative mood: "fix bug" not "fixed bug"
- Lowercase start: "fix: memory leak" not "Fix: Memory Leak"
- No period at the end
- Be specific but brief

---

## Commit Types

| Type | Usage | Example |
|---::|---|---|
| `feat` | New feature | `feat: add room pooling system` |
| `fix` | Bug fix | `fix: voice isolation not working` |
| `refactor` | Code restructuring | `refactor: extract room validation` |
| `perf` | Performance improvement | `perf: optimize camera switching` |
| `docs` | Documentation only | `docs: update room system guide` |
| `style` | Formatting | `style: format with stylua` |
| `test` | Adding/updating tests | `test: add seat assignment tests` |
| `chore` | Maintenance | `chore: update dependencies` |

---

## Examples

```bash
# GOOD
git commit -m "fix: camera stuttering on speaker change"
git commit -m "feat: add 4v4 room support"
git commit -m "perf: implement room pooling"
git commit -m "refactor: extract voice validation logic"
git commit -m "fix: seat assignment race condition"
git commit -m "feat: add voice activity debounce"
git commit -m "chore: clean up unused room connections"

# BAD
git commit -m "fixed the camera bug that was causing issues when switching"
git commit -m "update code"
git commit -m "improvements"
git commit -m "WIP"
git commit -m "misc changes"
```

---

## Specific Scopes (optional)

You can append a scope in parentheses for clarity:

```bash
git commit -m "fix(voice): isolation breaks on room rejoin"
git commit -m "feat(rooms): add pool size cap"
git commit -m "perf(camera): throttle update to 10fps"
git commit -m "fix(seats): occupant check before assignment"
```

---

## Pre-Commit Checklist

Before committing any Luau file:

- [ ] `selene path/to/File.luau` — no errors
- [ ] `stylua path/to/File.luau` — formatted
- [ ] Copyright header present
- [ ] No `print()` debug statements
- [ ] No TODO comments
- [ ] File is in the correct folder per naming conventions
