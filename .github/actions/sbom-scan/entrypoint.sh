#!/usr/bin/env bash
set -euo pipefail

cd /github/workspace

REQUIREMENTS_PATH="${INPUT_REQUIREMENTS_PATH:-requirements.txt}"
SBOM_PATH="${INPUT_SBOM_PATH:-sbom.json}"

if [ ! -f "$REQUIREMENTS_PATH" ]; then
  echo "Requirements file not found: $REQUIREMENTS_PATH"
  exit 1
fi

echo "Generating CycloneDX SBOM from $REQUIREMENTS_PATH"
syft scan "file:${REQUIREMENTS_PATH}" -o "cyclonedx-json=${SBOM_PATH}"

echo "Scanning SBOM with grype (fail on critical vulnerabilities)"
grype "sbom:${SBOM_PATH}" --by-cve --fail-on critical

echo "sbom_path=${SBOM_PATH}" >> "$GITHUB_OUTPUT"
