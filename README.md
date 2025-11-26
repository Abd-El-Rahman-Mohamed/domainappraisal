# Dynadot Domain Appraisal Script

## Overview

This repository contains a Bash script for querying the Dynadot domain appraisal API. It uses `curl` to send an HTTP/2 GET request with custom headers, cookies, and handles compressed responses to estimate the value of a domain (e.g., helloworld.com).

The script replicates a browser-like request, useful for automating domain valuations from the command line.

## Features

- Sends authenticated requests with Cloudflare clearance and session cookies.
- Supports HTTP/2 protocol.
- Automatically decompresses gzip/br responses for readable JSON output.
- Customizable for different domains via parameters.

## Prerequisites

- Linux environment (tested on Fedora/CentOS-like systems).
- `curl` installed (usually pre-installed; if not, `sudo dnf install curl` or equivalent).
- A valid `cf_clearance` cookie (obtained from browser dev tools after visiting [Dynadot](https://www.dynadot.com/domain/appraisal) and solving any CAPTCHA).

**Note:** Cookies, especially `cf_clearance`, expire quickly. Refresh them periodically from your browser.

## Usage

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/dynadot-appraisal-script.git
   cd dynadot-appraisal-script
   ```

2. Make the script executable:
   ```
   chmod +x appraisal.sh
   ```

3. Edit `appraisal.sh` to update the domain (e.g., replace `helloworld.com` with your target) and refresh cookies if needed.

4. Run the script:
   ```
   ./appraisal.sh
   ```

   Output will be the API response in JSON format. To save to a file:
   ```
   ./appraisal.sh > output.json
   ```

## Script Details

The core command in `appraisal.sh` is:

```bash
#!/bin/bash

curl -X GET 'https://www.dynadot.com/dynadot-vue-api/dynadot-service/domain-appraisal-api?command=appraisal&domain=helloworld.com&lang=en' \
--http2 \
--compressed \
-H 'Host: www.dynadot.com' \
-H 'Cookie: cf_clearance=YOUR_CF_CLEARANCE_HERE; new_ref=4869-1761414451235==2071-1761768036752; welcome_page=6J6A8B8Y7q7T7ADZ7M74716X9GU8V8sfk8p7R6k7f6z8p9I7d6n7Z8I6Ofh8p8c9P9KJ7Z6R7o7c63618Jg8d7f7g6a6p6y8u7NH8Q; fp_err_msg=; _iidt=manyduBWMqMlyxYdYRPHxFTnZLoTSmdzQle1govoiL/MuooFDfnVjDzI2bEgRO/G6UzCYrTuNsswaA==; _vid_t=4WQR+FnXRX9Ba/ngtjkfjf/dbU3nuvDN/qd6kkYz2PC1TScc1o7sbdpVJptpTPBOSn+H97KGpVPEBg==; request_id=1761824484764.YjDzGY; lang=en; light=light; dynadot_web_theme=light; language_id=3; account_signin=; save_id=; privacy_notice_dismiss=1; glbl_curr=0; cart_id=; close_language_tip=1; signin_verify=; session_id=36617598' \
-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0' \
-H 'Accept: */*' \
-H 'Accept-Language: en-US,en;q=0.5' \
-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Referer: https://www.dynadot.com/domain/appraisal' \
-H 'Content-Language: en' \
-H 'Dyna-Client-Type: Web' \
-H 'Sec-Fetch-Dest: empty' \
-H 'Sec-Fetch-Mode: cors' \
-H 'Sec-Fetch-Site: same-origin' \
-H 'Priority: u=0' \
-H 'Te: trailers' \
-H 'Connection: keep-alive'
```

Replace `YOUR_CF_CLEARANCE_HERE` with a fresh token.

## Troubleshooting

- **Binary Output:** If response is garbled, ensure `--compressed` is used.
- **403 Forbidden:** Refresh cookies, especially `cf_clearance`.
- **Rate Limiting:** Dynadot may limit requests; use responsibly.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Pull requests welcome! For major changes, open an issue first.
