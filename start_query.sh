#!/bin/bash

query="$1"
# Set the number of successful responses required (n)
n="$2"  # Edit this value to your desired number of successes

# Set the URL to curl
url="http://localhost:7070/v1/nes/query/execute-query"  # Replace with your actual URL

# Function to execute the curl and check for success
function call_with_check() {
  response=$(curl -d@"$query/nesquery.json" -s "$url")
  echo "$response"
  if [[ $(echo "$response" | jq '.status != "ERROR"') == "true" ]]; then
    ((success_count++))
    echo "Successful response: $success_count Query($(echo "$response" | jq '.queryId'))"
  else
    echo "Failed response: $response"
  fi
}

# Initialize success counter
success_count=0

# Loop until n successful responses are received
while [[ $success_count -lt $n ]]; do
  call_with_check
done

echo "Successfully received $n responses."
