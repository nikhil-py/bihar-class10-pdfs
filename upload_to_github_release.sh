#!/bin/bash
set -euo pipefail

REPO="nikhil-py/bihar-class10-pdfs"
TAG="v1.0"
VAULT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Bihar Class 10 Study Vault -> GitHub Release Uploader ==="
echo "Vault Dir: $VAULT_DIR"
echo "Target Repo: https://github.com/$REPO (Release $TAG)"

if ! command -v gh >/dev/null 2>&1; then
  echo "Installing GitHub CLI (gh) via Homebrew..."
  brew install gh
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Please sign in to GitHub CLI (nikhil-py):"
  gh auth login -h github.com -p https -w
fi

# Create public repo if it does not exist yet
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Creating public GitHub repository: $REPO ..."
  gh repo create "$REPO" --public --description "Bihar Board Class 10 Study Vault PDFs for Matric Objective App"
fi

# Initialize git on main and push lightweight README/INDEX.md (only ~8 KB, zero bloat!)
cd "$VAULT_DIR"
if [ ! -d ".git" ]; then
  git init -b main
  git remote add origin "https://github.com/$REPO.git"
fi

cat > .gitignore << 'EOF'
*.pdf
.DS_Store
EOF

git add .gitignore INDEX.md upload_to_github_release.sh
git commit -m "Initialize Bihar Class 10 PDF vault metadata (binaries hosted in Releases)" || true
git push -u origin main || true

# Create Release v1.0 if missing
if ! gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Creating Release $TAG ..."
  gh release create "$TAG" --repo "$REPO" --title "Bihar Board Class 10 Complete Study Vault (67 PDFs)" --notes "Official audited NCERT Hindi/English, BSEB Model Papers, PYQ Papers (2023-2026), and SCERT textbooks."
fi

# Upload all 67 PDFs directly as Release assets (--clobber safely overwrites/resumes any partial file)
COUNT=0
TOTAL=$(find "$VAULT_DIR" -type f -name "*.pdf" | wc -l | tr -d ' ')
echo "Uploading $TOTAL PDFs to GitHub Release $TAG..."

while IFS= read -r -d '' pdf; do
  COUNT=$((COUNT + 1))
  NAME=$(basename "$pdf")
  echo "[$COUNT/$TOTAL] Uploading $NAME ..."
  gh release upload "$TAG" "$pdf" --repo "$REPO" --clobber
done < <(find "$VAULT_DIR" -type f -name "*.pdf" -print0 | sort -z)

echo "✅ Done! All $COUNT PDFs are live at https://github.com/$REPO/releases/tag/$TAG"
