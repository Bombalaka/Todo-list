#!/usr/bin/env bash
set -Eeuo pipefail

# Build and push docker image to docker hub


# ------- CONFIG -------
: "${DOCKER_USERNAME:?Set DOCKER_USERNAME}"
: "${DOCKER_PASSWORD:?Set DOCKER_PASSWORD}"

# change version if you want: ./publish.sh 1.1
#VERSION="${1:-1.0}"
VERSION="${1:-2.0}"

IMAGE_REPO="${DOCKER_USERNAME}/todo-app"

# Path to backend Dockerfile (it also builds frontend)
DOCKERFILE_PATH="backend/Todo_App/Dockerfile"
BUILD_CONTEXT="."

# ----------------------

echo "Logging in to Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

echo "🏗️  Building fullstack image (frontend + backend)..."
docker build \
  -t "${IMAGE_REPO}:${VERSION}" \
  -f "${DOCKERFILE_PATH}" \
  "${BUILD_CONTEXT}"

docker tag "${IMAGE_REPO}:${VERSION}" "${IMAGE_REPO}:latest"

echo "🚀 Pushing image to Docker Hub..."
docker push "${IMAGE_REPO}:${VERSION}"
docker push "${IMAGE_REPO}:latest"

echo "✅ Done! Your fullstack image is available as:"
echo "   ${IMAGE_REPO}:${VERSION}"
echo "   ${IMAGE_REPO}:latest"

