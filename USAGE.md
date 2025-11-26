# Domain Appraisal Script

This Bash script queries the Dynadot domain appraisal API through Tor proxy and extracts domain prices.

## Prerequisites

1. **Tor** - Install and start Tor service:
   ```bash
   sudo apt-get install tor torsocks
   sudo systemctl start tor
   ```

2. **jq** (optional but recommended) - For better JSON parsing:
   ```bash
   sudo apt-get install jq
   ```

## Usage

```bash
./domain_appraisal.sh <input_file> <output_file>
```

### Example

```bash
./domain_appraisal.sh sample.txt results.csv
```

## Input Format

The input file should contain one domain per line:
```
aaadapter.com
aaagolfworld.com
aaallways.com
```

## Output Format

The output CSV file will contain:
```
domain1.com, 1234
domain2.com, 5678
domain3.com, 910
```

## Error Handling

The script will display warnings for:
- Empty API responses
- API errors (code >= 400, e.g., "Too many queries today")
- Domains where price extraction fails

Example error:
```
⚠️  WARNING: domain.com - Error 500: Too many queries today, please try again tomorrow!
```

## Features

- Routes all requests through Tor proxy for anonymity
- Handles API rate limiting with 2-second delays
- Supports both jq and grep/sed for JSON parsing
- Provides detailed progress and summary statistics
- Properly handles HTTP 200 (success) vs error codes
