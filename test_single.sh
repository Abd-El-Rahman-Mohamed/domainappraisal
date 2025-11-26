#!/bin/bash

domain="aaadapter.com"

echo "Testing API response for: $domain"
echo "=================================="

response=$(torify curl -s -X GET \
    "https://www.dynadot.com/dynadot-vue-api/dynadot-service/domain-appraisal-api?command=appraisal&domain=${domain}&lang=en" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0" \
    -H "Accept: */*" \
    -H "Referer: https://www.dynadot.com/domain/appraisal" \
    2>&1)

echo "Raw response:"
echo "$response"
echo ""
echo "Response length: ${#response}"
echo ""

if command -v jq &> /dev/null; then
    echo "Formatted JSON:"
    echo "$response" | jq . 2>/dev/null || echo "Not valid JSON"
fi
