#!/bin/bash

GITLAB_URL="https://gitlab.example.com"
# NOTE: You should use encoded path 
GROUP_PATH="systems%2Fgroup%2Finfra%2Fenv-promote"  
ACCESS_TOKEN="YOUR_PERSONAL_ACCESS_TOKEN"

# Get the group ID
RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
  "$GITLAB_URL/api/v4/groups/$GROUP_PATH")

GROUP_ID=$(echo "$RESPONSE" | jq -r .id 2>/dev/null)

if [ "$GROUP_ID" == "null" ] || [ -z "$GROUP_ID" ]; then
  echo "Failed to get group ID. API response was:"
  echo "$RESPONSE"
  exit 1
fi

echo "Group ID: $GROUP_ID"

PAGE=1
while :; do
  PROJECTS=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
    "$GITLAB_URL/api/v4/groups/$GROUP_ID/projects?per_page=100&page=$PAGE")
  COUNT=$(echo "$PROJECTS" | jq length 2>/dev/null)
  if [ "$COUNT" == "" ] || [ "$COUNT" -eq 0 ]; then
    echo "No more projects or API error. Last response:"
    echo "$PROJECTS"
    break
  fi
# use '.[].ssh_url_to_repo' in the following line to use ssh
  echo "$PROJECTS" | jq -r '.[].http_url_to_repo' | while read -r repo; do
    git clone "$repo"
  done

  PAGE=$((PAGE+1))
done
