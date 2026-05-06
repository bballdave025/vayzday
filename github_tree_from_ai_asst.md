Generate a Linux-style tree view of this repository.

Requirements:
- Exclude the following directories:
  - .git
  - __pycache__
  - .ipynb_checkpoints
  - .pytest_cache
  - .mypy_cache
  - .venv (and any virtual environment folders like venv/)
- Exclude compiled files:
  - *.pyc
  - *.pyo
- Show directories clearly (with trailing slash if possible)
- Keep output concise but complete for source structure

If possible, use a command like `tree` with appropriate flags.
If tree is not available, simulate it using `find` or similar.

Goal: clean view of source layout only.

---

Give me a clean Linux-style tree of this repo focused on source structure.

Exclude noise:
.git/
__pycache__/
.ipynb_checkpoints/
.pytest_cache/
.mypy_cache/
.venv/ and venv/
*.pyc, *.pyo

Show:
- directories with trailing /
- files under src/, config, and root

If using `tree`, show the exact command used.
If not, simulate it.

I want something I can paste into docs.
