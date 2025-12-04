#!/bin/bash
#
# Build and push devcontainer image to GitLab Container Registry
#
# Usage:
#   ./build-and-push.sh           # Build and push with 'latest' tag
#   ./build-and-push.sh v1.0.0    # Build and push with specific tag
#
# Prerequisites:
#   - Docker installed and running
#   - Logged in to GitLab Container Registry:
#     docker login registry.gitlab.com
#

set -e

# Configuration
REGISTRY="registry.gitlab.com"
PROJECT="simplificationofficers/wordle-kata"
IMAGE_NAME="devcontainer"
FULL_IMAGE="$REGISTRY/$PROJECT/$IMAGE_NAME"

# Get tag from argument or use 'latest'
TAG="${1:-latest}"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  DEVCONTAINER BUILD & PUSH${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Get script directory (where Dockerfile is)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}Registry:${NC}  $REGISTRY"
echo -e "${CYAN}Image:${NC}     $FULL_IMAGE"
echo -e "${CYAN}Tag:${NC}       $TAG"
echo ""

# Check if logged in to registry
echo -e "${YELLOW}Checking registry authentication...${NC}"
if ! docker pull "$FULL_IMAGE:latest" > /dev/null 2>&1; then
    echo -e "${YELLOW}Not logged in or image doesn't exist yet.${NC}"
    echo ""
    echo "To login to GitLab Container Registry, run:"
    echo -e "${CYAN}  docker login $REGISTRY${NC}"
    echo ""
    echo "Use your GitLab username and a Personal Access Token with 'read_registry' and 'write_registry' scopes."
    echo "Create a token at: https://gitlab.com/-/user_settings/personal_access_tokens"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build the image
echo ""
echo -e "${CYAN}Building image...${NC}"
echo ""

docker build \
    --tag "$FULL_IMAGE:$TAG" \
    --tag "$FULL_IMAGE:latest" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

echo ""
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Push the image
echo -e "${CYAN}Pushing image...${NC}"
echo ""

docker push "$FULL_IMAGE:$TAG"
docker push "$FULL_IMAGE:latest"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SUCCESS!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Image pushed successfully:"
echo -e "  ${CYAN}$FULL_IMAGE:$TAG${NC}"
echo -e "  ${CYAN}$FULL_IMAGE:latest${NC}"
echo ""
echo "Team members can now open the project in VS Code and"
echo "select 'Reopen in Container' to use the pre-built image."
echo ""
