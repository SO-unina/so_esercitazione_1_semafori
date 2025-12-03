#!/bin/bash

LOG="$1"

# Extract first gcc-style error
LINE=$(grep -oP '.*error:.*' "$LOG" | head -1)

if [[ -z "$LINE" ]]; then
    echo ""
    exit 0
fi

# Prepare JSON for OpenAI request
JSON=$(jq -n --arg ERR "$LINE" '
{
  "model": "gpt-4.1-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are an analysis assistant for C programming errors. Always answer EXACTLY in this template:

Error: (line of the error and short description of the error)
Fix: (line to fix and short description of the fix)

The response MUST NOT include text outside this template."
    },
    {
      "role": "user",
      "content": $ERR
    }
  ]
}')

# Call OpenAI API
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$JSON")

# Extract message content
echo "$RESPONSE" | jq -r '.choices[0].message.content'
