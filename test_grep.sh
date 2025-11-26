#!/bin/bash

# Test response from your output
response='{"code" : 200,"msg" : "success","data" : {"make_offer" : false,"name_utf" : "aaadapter.com","show_whois" : false,"value" : 1234}}'

echo "Testing grep patterns on sample response:"
echo "$response"
echo ""

echo "Pattern 1 - value field:"
echo "$response" | grep -o '"value"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*'

echo ""
echo "Pattern 2 - using grep -oP:"
echo "$response" | grep -oP '"value"\s*:\s*\K[0-9]+' || echo "Failed"

echo ""
echo "Pattern 3 - simple grep:"
echo "$response" | grep -o '"value" : [0-9]*' | grep -o '[0-9]*'
