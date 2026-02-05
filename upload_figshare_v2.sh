#!/data/data/com.termux/files/usr/bin/bash
# Robust Figshare file upload to EXISTING article (v2 - fixed flow)
# Usage: ./upload_figshare_v2.sh [ARTICLE_ID] [FILE_PATH]
# Defaults: ARTICLE_ID=31223029, FILE=ESQET_Whitepaper_v2.1_FINAL.md
# Token from: ~/.figshare_token

set -euo pipefail

TOKEN_FILE="$HOME/.figshare_token"
if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "❌ ERROR: Token file missing: $TOKEN_FILE"
    exit 1
fi
TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')

ARTICLE_ID="${1:-31223029}"
FILE_PATH="${2:-ESQET_Whitepaper_v2.1_FINAL.md}"

if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ ERROR: File not found: $FILE_PATH"
    exit 1
fi

# Compute required metadata
FILE_NAME=$(basename "$FILE_PATH")
FILE_SIZE=$(stat -c %s "$FILE_PATH" 2>/dev/null || stat -f %z "$FILE_PATH")
FILE_MD5=$(md5sum "$FILE_PATH" 2>/dev/null | cut -d' ' -f1 || md5 -q "$FILE_PATH")

echo "🜛 ESQET Figshare Upload v2"
echo "  Article ID : $ARTICLE_ID"
echo "  File       : $FILE_NAME ($FILE_SIZE bytes, MD5: $FILE_MD5)"
echo ""

# ────────────────────────────────────────────────
# Step 1: Initiate upload (POST metadata → get upload_url)
# ────────────────────────────────────────────────
echo "📤 Step 1/3: Initiating upload..."

INIT_JSON=$(jq -n \
    --arg name "$FILE_NAME" \
    --argjson size "$FILE_SIZE" \
    --arg md5 "$FILE_MD5" \
    '{name: $name, size: $size, supplied_md5: $md5}')

INIT_RESPONSE=$(curl -s -w "%{http_code}" -o init.json \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/files" \
    -d "$INIT_JSON")

HTTP_CODE="${INIT_RESPONSE##* }"
echo "  HTTP: $HTTP_CODE"

if [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "200" ]]; then
    echo "❌ INIT FAILED ($HTTP_CODE)"
    cat init.json
    exit 1
fi

# Extract upload_url and file_id
UPLOAD_URL=$(jq -r '.upload_url // empty' init.json)
FILE_ID=$(jq -r '.id // empty' init.json)

if [[ -z "$UPLOAD_URL" ]]; then
    echo "❌ No upload_url in response"
    cat init.json
    exit 1
fi

echo "  Upload URL: $UPLOAD_URL"
echo "  File ID   : $FILE_ID"

# ────────────────────────────────────────────────
# Step 2: Upload file content (PUT to upload_url)
# ────────────────────────────────────────────────
echo "📤 Step 2/3: Uploading file content..."
UPLOAD_HTTP=$(curl -s -w "%{http_code}" -o upload.log \
    -X PUT "$UPLOAD_URL" \
    -H "Authorization: token $TOKEN" \
    --data-binary @"$FILE_PATH")

echo "  HTTP: $UPLOAD_HTTP"

if [[ "$UPLOAD_HTTP" != "200" && "$UPLOAD_HTTP" != "201" ]]; then
    echo "❌ UPLOAD FAILED ($UPLOAD_HTTP)"
    cat upload.log
    exit 1
fi

echo "✅ File content uploaded!"

# ────────────────────────────────────────────────
# Step 3: Complete / finalize (if required; often auto-completes)
# ────────────────────────────────────────────────
echo "📤 Step 3/3: Completing upload..."
COMPLETE_HTTP=$(curl -s -w "%{http_code}" -o complete.json \
    -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/files/$FILE_ID" \
    -H "Authorization: token $TOKEN")

echo "  HTTP: $COMPLETE_HTTP"

if [[ "$COMPLETE_HTTP" != "200" && "$COMPLETE_HTTP" != "201" && "$COMPLETE_HTTP" != "204" ]]; then
    echo "⚠️ Complete step failed ($COMPLETE_HTTP) - but file may still be attached"
    cat complete.json
fi

# ────────────────────────────────────────────────
# Optional: Publish (uncomment if needed)
# ────────────────────────────────────────────────
# echo "📤 Publishing article..."
# PUBLISH_HTTP=$(curl -s -w "%{http_code}" \
#     -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/publish" \
#     -H "Authorization: token $TOKEN")
# echo "  Publish HTTP: $PUBLISH_HTTP"

# ────────────────────────────────────────────────
# Final output
# ────────────────────────────────────────────────
echo ""
echo "🎉 SUCCESS!"
echo "  DOI (draft): 10.6084/m9.figshare.$ARTICLE_ID"
echo "  Check:     https://figshare.com/account/articles/$ARTICLE_ID"
echo "  Public (after publish): https://figshare.com/articles/dataset/.../$ARTICLE_ID"

# Cleanup
rm -f init.json upload.log complete.json
