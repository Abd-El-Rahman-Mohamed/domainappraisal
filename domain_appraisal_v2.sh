#!/bin/bash

# Domain Appraisal Script via Tor - Version 2
# Usage: ./domain_appraisal_v2.sh <input_file> <output_file>

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

# Check if jq is available for JSON parsing
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

# Clear output file or create new one
> "$OUTPUT_FILE"

echo "Starting domain appraisal via Tor..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "JSON parser: $([ "$HAS_JQ" = true ] && echo "jq (available)" || echo "grep/sed (fallback)")"
echo ""

# Counters
total=0
success=0
errors=0

# Read domains line by line
while IFS= read -r domain || [ -n "$domain" ]; do
    # Skip empty lines
    [ -z "$domain" ] && continue
    
    # Trim whitespace
    domain=$(echo "$domain" | xargs)
    [ -z "$domain" ] && continue
    
    total=$((total + 1))
    echo -n "[$total] Processing: $domain ... "
    
    # Make the API request through Tor
    response=$($TOR_CMD curl -s -w "\nHTTP_CODE:%{http_code}" \
        "https://www.dynadot.com/dynadot-vue-api/dynadot-service/domain-appraisal-api?command=appraisal&domain=${domain}&lang=en" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0" \
        -H "Accept: application/json, */*" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Referer: https://www.dynadot.com/domain/appraisal" \
        -H "Dyna-Client-Type: Web" \
        2>&1)
    
    # Extract HTTP code
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    # Check HTTP status
    if [ "$http_code" != "200" ] && [ -n "$http_code" ]; then
        echo "FAILED (HTTP $http_code)"
        echo "  ⚠️  WARNING: $domain - HTTP error $http_code"
        errors=$((errors + 1))
        continue
    fi
    
    # Check if response is empty
    if [ -z "$response_body" ] || [ "$response_body" = "null" ]; then
        echo "FAILED (empty response)"
        echo "  ⚠️  WARNING: $domain - Empty or null response from API"
        errors=$((errors + 1))
        continue
    fi
    
    # Parse JSON response
    if [ "$HAS_JQ" = true ]; then
        # Use jq for reliable JSON parsing
        error_code=$(echo "$response_body" | jq -r '.code // empty' 2>/dev/null || echo "")
        error_msg=$(echo "$response_body" | jq -r '.msg // empty' 2>/dev/null || echo "")
        price=$(echo "$response_body" | jq -r '.data.price // .price // .appraisal_price // .value // empty' 2>/dev/null || echo "")
    else
        # Fallback to grep/sed
        error_code=$(echo "$response_body" | grep -oP '"code"[[:space:]]*:[[:space:]]*\K[0-9]+' | head -1 || echo "")
        error_msg=$(echo "$response_body" | grep -oP '"msg"[[:space:]]*:[[:space:]]*"\K[^"]+' | head -1 || echo "")
        
        # Try multiple price patterns
        price=$(echo "$response_body" | grep -oP '"price"[[:space:]]*:[[:space:]]*\K[0-9]+' | head -1 || echo "")
        if [ -z "$price" ]; then
            price=$(echo "$response_body" | grep -oP '"appraisal_price"[[:space:]]*:[[:space:]]*\K[0-9]+' | head -1 || echo "")
        fi
        if [ -z "$price" ]; then
            price=$(echo "$response_body" | grep -oP '"value"[[:space:]]*:[[:space:]]*\K[0-9]+' | head -1 || echo "")
        fi
    fi
    
    # Check for API errors (code >= 400 or specific error codes)
    if [ -n "$error_code" ] && [ "$error_code" -ge 400 ]; then
        echo "ERROR"
        echo "  ⚠️  WARNING: $domain - API Error $error_code: ${error_msg:-Unknown error}"
        errors=$((errors + 1))
        continue
    fi
    
    # Check if we got a price
    if [ -z "$price" ]; then
        echo "FAILED (no price)"
        echo "  ⚠️  WARNING: $domain - Could not extract price"
        echo "  Response: ${response_body:0:150}..."
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
