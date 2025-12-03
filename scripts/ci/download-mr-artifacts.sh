#!/bin/bash

set -euo pipefail

# Required environment variables (from GitLab CI)
: "${CI_JOB_TOKEN:?CI_JOB_TOKEN is required}"
: "${CI_API_V4_URL:?CI_API_V4_URL is required}"
: "${CI_PROJECT_ID:?CI_PROJECT_ID is required}"
: "${CI_COMMIT_SHA:?CI_COMMIT_SHA is required}"
: "${MODULE_NAME:?MODULE_NAME is required}"

# Job and artifact naming
JOB_NAME="${MODULE_NAME}_plan"
OUTPUT_FILE="plan-${MODULE_NAME}.zip"

echo "🔍 Finding MR associated with merge commit: ${CI_COMMIT_SHA}"

# Get the MR that was merged
MR_RESPONSE=$(curl --silent --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/repository/commits/${CI_COMMIT_SHA}/merge_requests")

MR_IID=$(echo "${MR_RESPONSE}" | jq -r '.[0].iid')

if [ -z "${MR_IID}" ] || [ "${MR_IID}" == "null" ]; then
  echo "❌ Could not find associated MR for commit ${CI_COMMIT_SHA}"
  echo "API Response: ${MR_RESPONSE}"
  exit 1
fi

echo "✅ Found MR: !${MR_IID}"

# Get the source branch of the MR
MR_DETAILS=$(curl --silent --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${MR_IID}")

MR_SOURCE_BRANCH=$(echo "${MR_DETAILS}" | jq -r '.source_branch')

if [ -z "${MR_SOURCE_BRANCH}" ] || [ "${MR_SOURCE_BRANCH}" == "null" ]; then
  echo "❌ Could not get source branch for MR !${MR_IID}"
  exit 1
fi

echo "📦 Downloading artifacts from job '${JOB_NAME}' on branch: ${MR_SOURCE_BRANCH}"

# URL encode the branch name (handles special characters like /)
ENCODED_BRANCH=$(printf '%s' "${MR_SOURCE_BRANCH}" | jq -sRr @uri)

# Download artifacts from the plan job on the MR source branch
HTTP_CODE=$(curl --silent --location --output "${OUTPUT_FILE}" --write-out "%{http_code}" \
  --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/jobs/artifacts/${ENCODED_BRANCH}/download?job=${JOB_NAME}")

if [ "${HTTP_CODE}" != "200" ]; then
  echo "❌ Failed to download artifacts (HTTP ${HTTP_CODE})"
  echo "URL: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/jobs/artifacts/${ENCODED_BRANCH}/download?job=${JOB_NAME}"
  rm -f "${OUTPUT_FILE}"
  exit 1
fi

echo "✅ Artifacts downloaded: ${OUTPUT_FILE}"

# Extract artifacts
unzip -o "${OUTPUT_FILE}"
rm -f "${OUTPUT_FILE}"

echo "✅ Artifacts extracted successfully"

# Verify tfplan exists
if [ ! -f "${MODULE_NAME}/tfplan" ]; then
  echo "❌ tfplan not found in extracted artifacts!"
  echo "Expected path: ${MODULE_NAME}/tfplan"
  echo "Available files:"
  find . -name "*.tf*" -o -name "tfplan" 2>/dev/null || true
  exit 1
fi

echo "✅ Verified: ${MODULE_NAME}/tfplan exists"
echo "🎉 Artifact download complete!"