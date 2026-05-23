#!/bin/bash
# Usage: scripts/new-project.sh <target-dir> [--template <name>] [--force]
#
#   <target-dir>          Path to the project root to scaffold into.
#   --template <name>     Template name (directory under templates/).
#                         If omitted, an interactive menu is shown.
#   --force               Overwrite an existing .devcontainer/ directory.
#
# Examples:
#   scripts/new-project.sh ~/Projects/my-app
#   scripts/new-project.sh ~/Projects/my-app --template vite-react-pnpm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/templates"

# ── Args ──────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 <target-dir> [--template <name>] [--force]"
  echo ""
  echo "Available templates:"
  ls "$TEMPLATES_DIR" | sed 's/^/  /'
  exit 1
}

TARGET_DIR=""
TEMPLATE=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      TEMPLATE="${2:-}"
      [ -z "$TEMPLATE" ] && { echo "✗ --template requires a value"; usage; }
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "✗ Unknown option: $1"
      usage
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      else
        echo "✗ Unexpected argument: $1"
        usage
      fi
      shift
      ;;
  esac
done

[ -z "$TARGET_DIR" ] && usage

# ── Template selection ────────────────────────────────────────────────────────

AVAILABLE=()
while IFS= read -r name; do
  AVAILABLE+=("$name")
done < <(ls "$TEMPLATES_DIR")

if [ ${#AVAILABLE[@]} -eq 0 ]; then
  echo "✗ No templates found in templates/"
  exit 1
fi

if [ -z "$TEMPLATE" ]; then
  echo "Select a template:"
  for i in "${!AVAILABLE[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${AVAILABLE[$i]}"
  done
  echo ""
  while true; do
    read -rp "Enter number [1-${#AVAILABLE[@]}]: " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE[@]} )); then
      TEMPLATE="${AVAILABLE[$((CHOICE - 1))]}"
      break
    fi
    echo "  Please enter a number between 1 and ${#AVAILABLE[@]}."
  done
fi

TEMPLATE_DIR="$TEMPLATES_DIR/$TEMPLATE"
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "✗ Template '$TEMPLATE' not found."
  echo ""
  echo "Available templates:"
  ls "$TEMPLATES_DIR" | sed 's/^/  /'
  exit 1
fi

# ── Resolve target (parent must exist; target itself may be new) ─────────────

PARENT_DIR="$(dirname "$TARGET_DIR")"
BASE_NAME="$(basename "$TARGET_DIR")"

RESOLVED_PARENT="$(cd "$PARENT_DIR" 2>/dev/null && pwd)" || {
  echo "✗ Parent directory does not exist: $PARENT_DIR"
  exit 1
}

TARGET_DIR="$RESOLVED_PARENT/$BASE_NAME"
DEVCONTAINER_DEST="$TARGET_DIR/.devcontainer"

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
  echo "✓ Created $TARGET_DIR"
fi

if [ -d "$DEVCONTAINER_DEST" ] && ! $FORCE; then
  echo "✗ $DEVCONTAINER_DEST already exists."
  echo "  Use --force to overwrite."
  exit 1
fi

# ── Copy template ─────────────────────────────────────────────────────────────

echo "→ Applying template '$TEMPLATE' to $(basename "$TARGET_DIR")"

cp -r "$TEMPLATE_DIR/.devcontainer" "$TARGET_DIR/"

echo "✓ Copied .devcontainer/"

# ── .gitignore ────────────────────────────────────────────────────────────────

GITIGNORE="$TARGET_DIR/.gitignore"
GITIGNORE_ENTRY=".devcontainer/local.env"

if [ -f "$GITIGNORE" ]; then
  if grep -qxF "$GITIGNORE_ENTRY" "$GITIGNORE"; then
    echo "✓ .gitignore already contains $GITIGNORE_ENTRY"
  else
    printf "\n%s\n" "$GITIGNORE_ENTRY" >> "$GITIGNORE"
    echo "✓ Added $GITIGNORE_ENTRY to .gitignore"
  fi
else
  printf "%s\n" "$GITIGNORE_ENTRY" > "$GITIGNORE"
  echo "✓ Created .gitignore with $GITIGNORE_ENTRY"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

PROJECT_NAME="$(basename "$TARGET_DIR")"

echo ""
echo "Done! Next steps:"
echo ""
echo "  1. Fill in secrets (never commit this file):"
echo "       $DEVCONTAINER_DEST/local.env"
echo ""
echo "  2. Open $PROJECT_NAME in Zed (or VS Code / Cursor) and choose:"
echo "       Reopen in Container"
echo ""
echo "  See templates/$TEMPLATE/README.md for customisation options."
