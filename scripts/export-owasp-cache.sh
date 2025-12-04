#!/bin/sh
#
# Export OWASP Dependency-Check database cache
# This creates a compressed archive that can be shared with other developers
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data/owasp-cache"
OUTPUT_FILE="$DATA_DIR/dependency-check-data.zip"

# Source database location
if [ -d "$HOME/.m2/repository/org/owasp/dependency-check-data" ]; then
    SOURCE_DIR="$HOME/.m2/repository/org/owasp/dependency-check-data"
else
    echo "ERROR: OWASP Dependency-Check database not found at:"
    echo "  $HOME/.m2/repository/org/owasp/dependency-check-data"
    echo ""
    echo "Run 'mvn dependency-check:check' in the backend folder first to download the database."
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  OWASP Dependency-Check Cache Export                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check source size
SOURCE_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
echo "Source database: $SOURCE_DIR"
echo "Database size: $SOURCE_SIZE"
echo ""

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Remove old archive if exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Removing old archive..."
    rm -f "$OUTPUT_FILE"
fi

# Create compressed archive
echo "Creating compressed archive..."
cd "$HOME/.m2/repository/org/owasp"
zip -r -9 "$OUTPUT_FILE" dependency-check-data/

# Show result
OUTPUT_SIZE=$(du -sh "$OUTPUT_FILE" | cut -f1)
echo ""
echo "Export complete!"
echo "  Output: $OUTPUT_FILE"
echo "  Size: $OUTPUT_SIZE"
echo ""
echo "Next steps:"
echo "  1. git add data/owasp-cache/dependency-check-data.zip"
echo "  2. git commit -m 'chore: add OWASP dependency-check cache'"
echo "  3. git push"
echo ""
echo "Other developers can then run:"
echo "  scripts/import-owasp-cache.bat  (Windows)"
echo "  scripts/import-owasp-cache.sh   (Mac/Linux)"
echo ""
