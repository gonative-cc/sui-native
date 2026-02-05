#!/bin/bash

# Ensure we exit on any error
set -e

if [ -z "$GITHUB_TOKEN" ]; then
  echo "::error::GITHUB_TOKEN is empty. Check your GITHUB_TOKEN secret."
  exit 1
fi

echo "Detected change in bitcoin_spv. Fetching relayer workflows..."

# Get active workflows from the relayer repo
WORKFLOWS=$(gh workflow list --repo gonative-cc/relayer --json path,state --jq '.[] | select(.state=="active") | .path | split("/") | last')

if [ -z "$WORKFLOWS" ]; then
  echo "No active workflows found in gonative-cc/relayer."
  exit 0
fi

FAILED_WORKFLOWS=""

for wf in $WORKFLOWS; do
  echo "🚀 Triggering: $wf"
  if ! gh workflow run "$wf" --repo gonative-cc/relayer --ref master; then
    echo "::error::Failed to trigger workflow '$wf' in gonative-cc/relayer."
    FAILED_WORKFLOWS="$FAILED_WORKFLOWS $wf"
  fi
done

if [ -n "$FAILED_WORKFLOWS" ]; then
  echo "::error::One or more workflows failed to trigger:${FAILED_WORKFLOWS}"
  exit 1
fi
