#!/bin/sh
#
# Import OWASP Dependency-Check database cache
# This extracts the pre-cached database to speed up first-time builds
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data/owasp-cache"
ARCHIVE_FILE="$DATA_DIR/dependency-check-data.zip"

# Target location
TARGET_DIR="$HOME/.m2/repository/org/owasp"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  OWASP Dependency-Check Cache Import                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if archive exists
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "ERROR: Cache archive not found at:"
    echo "  $ARCHIVE_FILE"
    echo ""
    echo "Make sure you have pulled the latest changes from the repository."
    exit 1
fi

# Show archive info
ARCHIVE_SIZE=$(du -sh "$ARCHIVE_FILE" | cut -f1)
echo "Archive: $ARCHIVE_FILE"
echo "Size: $ARCHIVE_SIZE"
echo "Target: $TARGET_DIR/dependency-check-data/"
echo ""

# Check if target already exists
if [ -d "$TARGET_DIR/dependency-check-data" ]; then
    echo "Existing database found. Backing up..."
    BACKUP_NAME="dependency-check-data.backup.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET_DIR/dependency-check-data" "$TARGET_DIR/$BACKUP_NAME"
    echo "Backup created: $TARGET_DIR/$BACKUP_NAME"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Extract archive
echo "Extracting database..."
unzip -o "$ARCHIVE_FILE" -d "$TARGET_DIR"

# Verify extraction
if [ -d "$TARGET_DIR/dependency-check-data" ]; then
    TARGET_SIZE=$(du -sh "$TARGET_DIR/dependency-check-data" | cut -f1)
    echo ""
    echo "Import complete!"
    echo "  Location: $TARGET_DIR/dependency-check-data/"
    echo "  Size: $TARGET_SIZE"
    echo ""
    echo "OWASP Dependency-Check will now use this cached database."
    echo "First Maven build with dependency-check will be much faster!"
else
    echo ""
    echo "ERROR: Extraction failed. Database directory not found."
    exit 1
fi
