#!/bin/bash

set -euo pipefail

# Required environment variables (from GitLab CI)
: "${GITLAB_TOKEN:?GITLAB_TOKEN is required}"
: "${CI_API_V4_URL:?CI_API_V4_URL is required}"
: "${CI_PROJECT_ID:?CI_PROJECT_ID is required}"
: "${CI_COMMIT_SHA:?CI_COMMIT_SHA is required}"
: "${MODULE_NAME:?MODULE_NAME is required}"

# Job naming
STATE_NAME=$(basename ${MODULE_NAME})
JOB_NAME="${STATE_NAME} (plan)"

echo "🔍 Finding MR associated with merge commit: ${CI_COMMIT_SHA}"

# Get the MR that was merged
MR_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/repository/commits/${CI_COMMIT_SHA}/merge_requests")

MR_IID=$(echo "${MR_RESPONSE}" | jq -r '.[0].iid')

if [ -z "${MR_IID}" ] || [ "${MR_IID}" == "null" ]; then
  echo "❌ Could not find associated MR for commit ${CI_COMMIT_SHA}"
  exit 1
fi

echo "✅ Found MR: !${MR_IID}"

# Get pipelines from the MR
PIPELINES_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${MR_IID}/pipelines")

PIPELINE_ID=$(echo "${PIPELINES_RESPONSE}" | jq -r '[.[] | select(.status == "success")] | .[0].id')

if [ -z "${PIPELINE_ID}" ] || [ "${PIPELINE_ID}" == "null" ]; then
  PIPELINE_ID=$(echo "${PIPELINES_RESPONSE}" | jq -r '.[0].id')
fi

if [ -z "${PIPELINE_ID}" ] || [ "${PIPELINE_ID}" == "null" ]; then
  echo "❌ Could not find any pipeline for MR !${MR_IID}"
  exit 1
fi

echo "✅ Found Pipeline ID: ${PIPELINE_ID}"

# Get job details from the pipeline
JOBS_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs")

# Find the specific job
JOB_INFO=$(echo "${JOBS_RESPONSE}" | jq -r --arg job "${JOB_NAME}" '.[] | select(.name == $job)')

if [ -z "${JOB_INFO}" ] || [ "${JOB_INFO}" == "null" ]; then
  echo "❌ Could not find job '${JOB_NAME}' in pipeline ${PIPELINE_ID}"
  echo "Available jobs:"
  echo "${JOBS_RESPONSE}" | jq -r '.[] | "  - \(.name) (\(.status))"'
  exit 1
fi

JOB_ID=$(echo "${JOB_INFO}" | jq -r '.id')
JOB_STATUS=$(echo "${JOB_INFO}" | jq -r '.status')
ARTIFACTS_FILE=$(echo "${JOB_INFO}" | jq -r '.artifacts_file.filename // "none"')
ARTIFACTS_EXPIRE=$(echo "${JOB_INFO}" | jq -r '.artifacts_expire_at // "never"')

echo "✅ Found Job ID: ${JOB_ID}"
echo "   Status: ${JOB_STATUS}"
echo "   Artifacts: ${ARTIFACTS_FILE}"
echo "   Expires: ${ARTIFACTS_EXPIRE}"

# Check if artifacts exist
if [ "${ARTIFACTS_FILE}" == "none" ] || [ "${ARTIFACTS_FILE}" == "null" ]; then
  echo "❌ Job has NO artifacts (expired or not produced)"
  exit 1
fi

# Download artifacts
OUTPUT_FILE="${STATE_NAME}.zip"

echo "📦 Downloading artifacts from job ${JOB_ID}..."

HTTP_CODE=$(curl --silent --location --output "${OUTPUT_FILE}" --write-out "%{http_code}" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/jobs/${JOB_ID}/artifacts")

if [ "${HTTP_CODE}" != "200" ]; then
  echo "❌ Failed to download artifacts (HTTP ${HTTP_CODE})"
  rm -f "${OUTPUT_FILE}"
  exit 1
fi

echo "✅ Downloaded: ${OUTPUT_FILE}"

# Extract artifacts
unzip -o "${OUTPUT_FILE}"
rm -f "${OUTPUT_FILE}"

# Verify required files
REQUIRED_FILES=(
  "${MODULE_NAME}/tfplan"
  "${MODULE_NAME}/.backend.hcl"
  "${MODULE_NAME}/.terraform.lock.hcl"
)

for FILE in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${FILE}" ]; then
    echo "❌ Missing: ${FILE}"
    exit 1
  fi
  echo "✅ Found: ${FILE}"
done

if [ ! -d "${MODULE_NAME}/.terraform/providers" ]; then
  echo "❌ Missing: ${MODULE_NAME}/.terraform/providers"
  exit 1
fi
echo "✅ Found: ${MODULE_NAME}/.terraform/providers"

echo "🎉 All artifacts downloaded successfully!"