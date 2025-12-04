#!/bin/sh
#
# Load environment variables from .env file if it exists
# This script sources the .env file and exports all variables
#
# Usage:
#   source scripts/load-env.sh
#   mvn dependency-check:check
#
# Or use it in a one-liner:
#   source backend/scripts/load-env.sh && mvn dependency-check:check

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Get the backend directory (parent of scripts/)
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$BACKEND_DIR/.env"

# Check if .env file exists
if [ -f "$ENV_FILE" ]; then
    # Export variables from .env file
    # This handles KEY=value format, ignoring comments and empty lines
    set -a  # Automatically export all variables
    . "$ENV_FILE"
    set +a  # Stop automatically exporting
    echo "✓ Loaded environment variables from $ENV_FILE"
else
    echo "⚠ .env file not found at $ENV_FILE"
    echo "  Create it with: NVD_API_KEY=your-key-here"
fi

