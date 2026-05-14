---
name: nano-pdf
description: Edit PDFs with natural-language instructions using the nano-pdf CLI.
homepage: https://pypi.org/project/nano-pdf/
metadata: {"clawdbot":{"emoji":"📄","requires":{"bins":["nano-pdf"]},"install":[{"id":"uv","kind":"uv","package":"nano-pdf","bins":["nano-pdf"],"label":"Install nano-pdf (uv)"}]}}
---

# nano-pdf

Use `nano-pdf` to apply edits to a specific page in a PDF using a natural-language instruction.

---

## 1. Prerequisites

- **Installed**: Verify `nano-pdf` is available: `nano-pdf --version`
- **File exists**: Confirm the PDF path is correct and accessible
- **Write permission**: Ensure user can write to the target directory

> **Fallback**: If `nano-pdf` is not installed, inform the user and suggest: `uv pip install nano-pdf` or `pip install nano-pdf`

---

## 2. Core Workflow

### Step 1 — Verify Tool Availability

```bash
nano-pdf --version
```

### Step 2 — Identify Target Page

- Confirm page number (0-based or 1-based — test with a non-critical page first if unsure)
- **Checkpoint**: If the PDF has many pages, confirm the target page number with the user before editing

### Step 3 — Execute Edit

```bash
nano-pdf edit <path_to_pdf> <page_number> "<instruction>"
```

### Step 4 — Verify Output

- Open/scan the modified PDF to confirm the edit was applied correctly
- Check that no unintended changes occurred on other pages

> **Fallback on page off-by-one**: If result looks wrong, retry with page±1

---

## 3. Error Handling

| Error | Fallback Action |
|---|---|
| `nano-pdf: command not found` | Prompt user to install via `uv pip install nano-pdf` |
| File not found | Verify path, check for typos, confirm file exists |
| Permission denied | Inform user, suggest checking file/directory permissions |
| Edit produced wrong result | Retry with adjusted page number or instruction rephrase |
| PDF is corrupted/password-protected | Inform user, do not attempt further edits |

---

## 4. Safety Checkpoints

Before executing an edit, confirm:

1. **Target page**: "You want to edit page N. Confirm?"
2. **Overwrite**: "This will modify the original file. Confirm?"
3. **Destructive intent**: If instruction implies deleting content, verify with user first

---

## 5. Best Practices

- Always work on a copy of the original PDF when possible
- Use precise, unambiguous instructions (e.g., "Change heading to 'Q3 Report'" instead of "Make it look better")
- After editing, sanity-check the output PDF before delivering
- If the tool fails repeatedly, fall back to manual editing or inform the user

---

## Quick Reference

```bash
# Basic edit
nano-pdf edit deck.pdf 1 "Change the title to 'Q3 Results'"

# Verify version
nano-pdf --version
```

**Notes**:
- Page numbers are 0-based or 1-based depending on the tool's version/config; if the result looks off by one, retry with the other.
- Always sanity-check the output PDF before sending it out.
