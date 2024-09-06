#!/bin/bash

# Set your GitHub personal access token
GITHUB_TOKEN="$1"

# Set the GitHub API URL
GITHUB_API_URL="https://api.github.com"

# Set the user or organization name
GITHUB_USER_OR_ORG="phyzical"

# Set the webhook URL and other configurations
WEBHOOK_URL="$2/github"
WEBHOOK_CONTENT_TYPE="json"
WEBHOOK_EVENTS='["push", "pull_request", "issues", "star", "status", "release", "issue_comment", "pull_request_review", "pull_request_review_comment", "fork"]'

# Function to create a webhook for a repository
create_webhook() {
  local repo=$1
  curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$GITHUB_API_URL/repos/$GITHUB_USER_OR_ORG/$repo/hooks" \
    -d @- <<EOF
{
  "name": "web",
  "active": true,
  "events": $WEBHOOK_EVENTS,
  "config": {
    "url": "$WEBHOOK_URL",
    "content_type": "$WEBHOOK_CONTENT_TYPE",
    "secret": "",
    "insecure_ssl": "0"
  }
}
EOF
}

# Fetch all repositories for the user or organization
repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "$GITHUB_API_URL/users/$GITHUB_USER_OR_ORG/repos")

echo "Repos: $repos"

repos=$(echo "$repos" | jq -r '.[].name')

# Loop through each repository and create a webhook
for repo in $repos; do
  echo "Creating webhook for repository: $repo"
  create_webhook "$repo"
done

echo "Webhooks created for all repositories."
