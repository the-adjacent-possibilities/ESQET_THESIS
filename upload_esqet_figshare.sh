#!/bin/bash
TOKEN=$(cat ~/.figshare_token 2>/dev/null || echo "NO_TOKEN")
ESQET_FILE="ESQET_Whitepaper_v2.1_FINAL.md"

echo "🜛 ESQET v2.1 Figshare Deployer"
echo "Token: ${TOKEN:0:8}... (${#TOKEN} chars)"

if [[ $TOKEN == "YOUR_TOKEN_HERE" || $TOKEN == "NO_TOKEN" ]]; then
    echo "❌ ERROR: Fix token first: echo 'YOUR_REAL_TOKEN' > ~/.figshare_token"
    exit 1
fi

# 1. CREATE ARTICLE
echo "📤 Creating ESQET article..."
RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: token $TOKEN" \
  -X POST https://api.figshare.com/v2/account/articles \
  -H "Content-Type: application/json" \
  -d '{
    "title": "ESQET v2.1: 25/25 Physics Unification (Rydberg Derived)",
    "description": "COMPLETE symbolic derivation of 25 fundamental constants from φ-torsion manifold. Rydberg: φ^(-27+2ξ)=1.0973731568160e7 m^-1 (0.00σ CODATA). Cañon City 5.54% torsion gain.",
    "keywords": ["Unified Field Theory","Torsion","Fine Structure","Rydberg"],
    "categories": [27318],
    "authors": [{"name": "Marco Antônio Rocha Jr.","orcid": "0009-0004-9757-2853"}]
  }')

HTTP_CODE=${RESPONSE: -3}
RESPONSE_BODY=${RESPONSE%???}

echo "HTTP: $HTTP_CODE"
echo "Response: $RESPONSE_BODY" | jq .

if [[ $HTTP_CODE == "201" ]]; then
    ARTICLE_ID=$(echo $RESPONSE_BODY | jq -r '.location | split("/")[-1]')
    echo "✅ Article ID: $ARTICLE_ID"
    
    # 2. UPLOAD FILE
    if [[ -f "$ESQET_FILE" ]]; then
        echo "📁 Uploading $ESQET_FILE..."
        curl -v -H "Authorization: token $TOKEN" \
          -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/files" \
          -F "file=@$ESQET_FILE"
        echo "✅ UPLOADED! DOI: 10.6084/m9.figshare.$ARTICLE_ID"
    else
        echo "❌ $ESQET_FILE not found. Create it first."
    fi
else
    echo "❌ Figshare API failed: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
fi
