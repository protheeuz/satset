# Commit Process

## Description

This skill is used by AGENTS to commit all previous changes into context-appropriate branches, push them to GitHub, and open Pull Requests. Merging is done manually by the repository owner on GitHub.

---

## Mandatory References

Before doing anything, **ALWAYS** read all files below first:

```bash
.agent/skills/humanizer/SKILL.md   → language & tone standard for commit messages and PR descriptions
.agent/skills/commit/SKILL.md      → commit format & structure standard
.github/PULL_REQUEST_TEMPLATE.md            → PR description template to follow
```

Do not proceed with any commit work until all three files have been read and understood.

---

## Workflow (Step-by-step)

### STEP 1 — Read Mandatory References

```bash
cat .agent/skills/humanizer/SKILL.md
cat .agent/skills/commit/SKILL.md
cat .github/PULL_REQUEST_TEMPLATE.md
```

Understand the language, tone, commit format, and PR description structure before continuing.

---

### STEP 2 — Ask for GitHub Account Confirmation

Before starting any Git activity, the AGENT **MUST** ask the user which GitHub account should be used for the commits and PRs in this session:

- **Account 1**: `protheeuz` (Primary)
- **Account 2**: `suckserberg` / `0.7%` (<mathtechstudio@gmail.com>)

After the user selects an account, the AGENT must configure the local identity and the GitHub CLI:

```bash
# For Account 1
git config user.name "protheeuz"
git config user.email "<primary-email>"
gh auth switch --user protheeuz

# For Account 2
git config user.name "0.7%"
git config user.email "mathtechstudio@gmail.com"
gh auth switch --user suckserberg
```

---

### STEP 3 — Ensure You Are on Branch `main`

```bash
git branch --show-current
```

If not on `main`, switch first:

```bash
git checkout main && git pull origin main
```

---

### STEP 4 — Check All Changes with `git status`

```bash
git status
```

Note all files that are:

- **Modified** → files that were edited
- **Untracked** → new files not yet tracked
- **Deleted** → files that were removed
- **Renamed** → files that were moved or renamed

---

### STEP 5 — Understand Change Details with `git diff`

For every file listed in `git status`, run:

```bash
git diff <file-name>
```

For untracked (new) files, use:

```bash
cat <file-name>
```

Purpose: understand **what actually changed** in each file so commit messages, branch names, and PR descriptions can be written with accurate, meaningful context.

---

### STEP 6 — Group Changes by Context

After reviewing all diffs, group the changed files into **separate context groups**. Each group will become its own branch and Pull Request.

**Branch naming follows the type of change:**

| Change Type | Branch Prefix | Example |
|---::|---:|---:|
| New feature | `feat/` | `feat/user-authentication` |
| Bug fix | `fix/` | `fix/login-redirect-loop` |
| Refactor | `refactor/` | `refactor/api-handler-cleanup` |
| Chore / config / tooling | `chore/` | `chore/update-env-example` |
| Tests | `test/` | `test/add-auth-unit-tests` |
| Documentation | `docs/` | `docs/update-readme` |

> **Rule:** One branch = one context. Never mix changes from different contexts into one branch.
> **Rule:** Even if there are only a few changes with a single context, still create a branch — never commit directly to `main`.

---

### STEP 7 — Create Branch, Commit, and Push Per Context

For each context group defined in Step 6:

#### 7a. Create a branch from `main`

```bash
git checkout main
git checkout -b <type>/<short-description>
```

The branch name must reflect the **type and subject** of the changes.

#### 7b. Stage only the relevant files for this context

```bash
git add <file-1> <file-2> ...
```

Do not use `git add .` — only stage files that belong to this specific context.

#### 7c. Write a commit message following the standard

Re-read `.agent/skills/commit/SKILL.md` and `.agent/skills/humanizer/SKILL.md` to ensure the correct format and tone.

```bash
git commit -m "<commit message following the standard>"
```

#### 7d. Push the branch to GitHub

```bash
git push origin <type>/<short-description>
```

#### 7e. Go back to `main` and repeat for the next context group

```bash
git checkout main
```

Repeat Steps 7a–7d for every remaining context group.

---

### STEP 8 — Open a Pull Request for Each Branch

After all branches have been pushed, open a Pull Request for each one targeting `main`.

#### PR Title

Must follow the commit message standard from `.agent/skills/commit/SKILL.md` and the tone from `.agent/skills/humanizer/SKILL.md`. The title should clearly summarize what the branch introduces or fixes.

#### PR Description

Must be filled using the structure from `.github/PULL_REQUEST_TEMPLATE.md`. Write the description content in the language and tone defined by `.agent/skills/humanizer/SKILL.md`. Fill in every section of the template based on the actual changes in the branch — do not leave sections empty or use placeholder text.

```bash
gh pr create \
  --base main \
  --head <type>/<short-description> \
  --title "<PR title following commit standard>" \
  --body-file <path-to-pr-body-file>
```

> **Do NOT merge the PR.** All merging is done manually by the repository owner on GitHub.

---

### STEP 9 — Final Verification

After all PRs are opened:

```bash
git status
gh pr list
```

Ensure:

- `git status` on `main` is clean — no uncommitted changes remaining
- All expected PRs are listed and in **Open** state, awaiting manual merge

---

## Important Rules

1. **ALWAYS** read `.agent/skills/humanizer/SKILL.md`, `.agent/skills/commit/SKILL.md`, and `.github/PULL_REQUEST_TEMPLATE.md` before starting — no exceptions.
2. **ALWAYS** ask for GitHub account confirmation (STEP 2) before any Git activity — ensure the correct `user.name` and `user.email` are set.
3. **NEVER** commit directly to `main` — always use a separate branch.
4. **NEVER** merge any branch — merging is done manually by the repository owner on GitHub.
5. **NEVER** use `git add .` — only stage files relevant to the current context.
6. **ALWAYS** run `git diff` before writing a commit message — the message must reflect what actually changed.
7. **ALWAYS** push the branch to GitHub after committing.
8. **ALWAYS** open a PR after pushing, with the title and description following the standards above.
9. **CREATE** more than one branch when changes span multiple contexts.
10. **NAME** branches using the correct type prefix (`feat/`, `fix/`, `refactor/`, `chore/`, `test/`, `docs/`) followed by a short, descriptive slug that reflects the actual change.
11. Commit messages and PR titles **MUST** follow `.agent/skills/commit/SKILL.md`. PR descriptions **MUST** use the template from `.github/PULL_REQUEST_TEMPLATE.md`, written in the tone from `.agent/skills/humanizer/SKILL.md`.

---

## Example Scenario

### Scenario: `git status` shows many changes across different contexts

```yaml
Modified:   src/components/Button.tsx
Modified:   src/components/Modal.tsx
Modified:   src/api/auth.ts
Modified:   src/utils/session.ts
Untracked:  src/tests/auth.test.ts
Modified:   .env.example
```

**Grouping:**

| Context | Files | Branch |
|---::|---|---|
| UI component update | `Button.tsx`, `Modal.tsx` | `feat/ui-component-update` |
| Auth & session fix | `auth.ts`, `session.ts`, `auth.test.ts` | `fix/auth-session-handling` |
| Environment config | `.env.example` | `chore/update-env-example` |

**Execution:**

```bash
# Read mandatory references
cat .agent/skills/humanizer/SKILL.md
cat .agent/skills/commit/SKILL.md
cat .github/PULL_REQUEST_TEMPLATE.md

# Branch 1: UI
git checkout main
git checkout -b feat/ui-component-update
git diff src/components/Button.tsx
git diff src/components/Modal.tsx
git add src/components/Button.tsx src/components/Modal.tsx
git commit -m "<commit message following standard>"
git push origin feat/ui-component-update
gh pr create \
  --base main \
  --head feat/ui-component-update \
  --title "<PR title following commit standard>" \
  --body "<PR description using PULL_REQUEST_TEMPLATE.md in humanizer language>"

# Branch 2: Auth
git checkout main
git checkout -b fix/auth-session-handling
git diff src/api/auth.ts
git diff src/utils/session.ts
cat src/tests/auth.test.ts
git add src/api/auth.ts src/utils/session.ts src/tests/auth.test.ts
git commit -m "<commit message following standard>"
git push origin fix/auth-session-handling
gh pr create \
  --base main \
  --head fix/auth-session-handling \
  --title "<PR title following commit standard>" \
  --body "<PR description using PULL_REQUEST_TEMPLATE.md in humanizer language>"

# Branch 3: Env
git checkout main
git checkout -b chore/update-env-example
git diff .env.example
git add .env.example
git commit -m "<commit message following standard>"
git push origin chore/update-env-example
gh pr create \
  --base main \
  --head chore/update-env-example \
  --title "<PR title following commit standard>" \
  --body "<PR description using PULL_REQUEST_TEMPLATE.md in humanizer language>"

# Verify
git status
gh pr list
```

---

## Summary Flow

```yaml
Read mandatory SKILL references + PR template
             ↓
git status → identify all changes
             ↓
git diff → understand details per file
             ↓
Group changes by context
             ↓
For each context:
  checkout main → create branch (feat/fix/chore/…) → stage files → commit → push → open PR
             ↓
All PRs open and awaiting manual merge on GitHub
```
