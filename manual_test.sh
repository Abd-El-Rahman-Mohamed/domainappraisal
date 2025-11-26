#!/bin/bash

echo "=== Manual Test of Price Extraction ===" > test_results.txt
echo "" >> test_results.txt

# Simulate the actual API response format based on your output
response='{"code" : 200,"msg" : "success","data" : {"make_offer" : false,"name_utf" : "aaadapter.com","show_whois" : false,"value" : 1234}}'

echo "Test Response:" >> test_results.txt
echo "$response" >> test_results.txt
echo "" >> test_results.txt

echo "Extracting price..." >> test_results.txt
price=$(echo "$response" | grep -o '"value"[[:space:]]*:[[:space:]]*[0-9][0-9]*' | grep -o '[0-9][0-9]*' | head -1)

echo "Extracted price: $price" >> test_results.txt
echo "" >> test_results.txt

if [ -n "$price" ]; then
    echo "SUCCESS: Price extracted = $price" >> test_results.txt
else
    echo "FAILED: Could not extract price" >> test_results.txt
fi

cat test_results.txt
