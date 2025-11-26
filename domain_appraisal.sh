#!/bin/bash

# Domain Appraisal Script via Tor
# Usage: ./domain_appraisal.sh <input_file> <output_file>

set -euo pipefail

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    echo "Example: $0 sample.txt results.csv"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

# Check if Tor proxy is available
if ! command -v torify &> /dev/null && ! command -v torsocks &> /dev/null; then
    echo "Error: Neither 'torify' nor 'torsocks' found. Please install Tor."
    echo "On Debian/Ubuntu: sudo apt-get install tor torsocks"
    exit 1
fi

# Determine which Tor command to use
if command -v torify &> /dev/null; then
    TOR_CMD="torify"
else
    TOR_CMD="torsocks"
fi

# Check if jq is available for better JSON parsing
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

# Clear output file or create new one
> "$OUTPUT_FILE"

echo "Starting domain appraisal via Tor..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Counters
total=0
success=0
errors=0

# Read domains line by line
while IFS= read -r domain || [ -n "$domain" ]; do
    # Skip empty lines and trim whitespace
    domain=$(echo "$domain" | xargs)
    [ -z "$domain" ] && continue
    
    total=$((total + 1))
    echo -n "[$total] Processing: $domain ... "
    
    # Make the API request through Tor
    response=$($TOR_CMD curl -s \
        "https://www.dynadot.com/dynadot-vue-api/dynadot-service/domain-appraisal-api?command=appraisal&domain=${domain}&lang=en" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0" \
        -H "Accept: */*" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Referer: https://www.dynadot.com/domain/appraisal" \
        -H "Dyna-Client-Type: Web" \
        2>&1)
    
    # Check if response is empty
    if [ -z "$response" ]; then
        echo "FAILED (empty response)"
        echo "  ⚠️  WARNING: $domain - Empty response from API"
        errors=$((errors + 1))
        continue
    fi
    
    # Parse JSON response
    if [ "$HAS_JQ" = true ]; then
        # Use jq for reliable JSON parsing
        error_code=$(echo "$response" | jq -r '.code // empty' 2>/dev/null || echo "")
        error_msg=$(echo "$response" | jq -r '.msg // empty' 2>/dev/null || echo "")
        # The value is nested in data object: data.value
        price=$(echo "$response" | jq -r '.data.value // .data.price // .price // .appraisal_price // .value // empty' 2>/dev/null || echo "")
    else
        # Fallback to grep/sed
        error_code=$(echo "$response" | grep -o '"code"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1 || echo "")
        error_msg=$(echo "$response" | grep -o '"msg"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1 || echo "")
        
        # Try multiple price patterns - looking for "value" field in data object
        # The API returns: "value" : 1234 (with spaces around colon)
        # Pattern 1: "value" : 123 or "value": 123 or "value":123
        price=$(echo "$response" | grep -o '"value"[[:space:]]*:[[:space:]]*[0-9][0-9]*' | grep -o '[0-9][0-9]*' | head -1 || echo "")
        
        # Pattern 2: "price" : 123
        if [ -z "$price" ]; then
            price=$(echo "$response" | grep -o '"price"[[:space:]]*:[[:space:]]*[0-9][0-9]*' | grep -o '[0-9][0-9]*' | head -1 || echo "")
        fi
        
        # Pattern 3: "appraisal_price" : 123
        if [ -z "$price" ]; then
            price=$(echo "$response" | grep -o '"appraisal_price"[[:space:]]*:[[:space:]]*[0-9][0-9]*' | grep -o '[0-9][0-9]*' | head -1 || echo "")
        fi
    fi
    
    # Check for error conditions (code >= 400 means error, 200 means success)
    if [ -n "$error_code" ] && [ "$error_code" -ge 400 ]; then
        echo "ERROR"
        echo "  ⚠️  WARNING: $domain - API Error $error_code: ${error_msg:-Unknown error}"
        errors=$((errors + 1))
        continue
    fi
    
    # Check if we got a price
    if [ -z "$price" ]; then
        echo "FAILED (no price)"
        echo "  ⚠️  WARNING: $domain - Could not extract price from response"
        echo "  Response preview: ${response:0:150}"
        errors=$((errors + 1))
    else
        echo "OK (\$$price)"
        echo "$domain, $price" >> "$OUTPUT_FILE"
        success=$((success + 1))
    fi
    
    # Add delay to avoid rate limiting
    sleep 2
    
done < "$INPUT_FILE"

echo ""
echo "========================================="
echo "Summary:"
echo "  Total domains: $total"
echo "  Successful: $success"
echo "  Errors: $errors"
echo "========================================="
echo "Results saved to: $OUTPUT_FILE"
