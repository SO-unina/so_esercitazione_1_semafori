#!/bin/bash

SRC_FILE="$1"

# Check if the file exists
if [[ ! -f "$SRC_FILE" ]]; then
    echo "Source file not found: $SRC_FILE"
    exit 1
fi

# Make sure we read it exactly as-is
CODE=$(cat "$SRC_FILE")

SYSTEM_PROMPT=$'You are a C static analysis assistant.

You will receive multiple source files combined into a single text.
Each file starts with a line in the format:
//// FILE: filename.c ////

Your job is to detect ONLY real, definite, proven programming errors that would
cause incorrect behavior, undefined behavior, segmentation faults, or compilation errors.

Do NOT report:
- missing includes (if another file includes them)
- missing return 0 in main
- style issues
- warnings
- best practices
- speculative or possible issues
- suggestions

If the code is correct, return EXACTLY:

Error: none
Fix: none

Otherwise follow this template exactly:

Error: (filename.c:line - short real error)
Fix: (filename.c:line - exact correction)

Do not use the exact line number in the report but use the statement as reference.
Do not suggest optional modifications to improve the design.
Never invent errors.
Never guess.
Never infer macro definitions beyond what is shown.
Never suggest changes unless the behavior is CERTAINLY incorrect.
Do not include anything else.'

JSON=$(jq -n \
  --arg SYSTEM "$SYSTEM_PROMPT" \
  --arg CODE "$CODE" \
  '
{
  "model": "gpt-4.1-mini",
  "messages": [
    { "role": "system", "content": $SYSTEM },
    { "role": "user",   "content": $CODE }
  ]
}
')

echo "[DEBUG] AI_KEY: ${AI_KEY}"

# Call OpenAI API
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${AI_KEY}" \
  -d "$JSON")

# Extract message content
echo "[DEBUG] RESPONSE: $RESPONSE"
echo "$RESPONSE" | jq -r '.choices[0].message.content'
