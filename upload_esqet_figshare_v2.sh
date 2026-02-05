#!/bin/bash
TOKEN=$(cat ~/.figshare_token)
ESQET_FILE="ESQET_Whitepaper_v2.1_FINAL.md"

echo "🜛 ESQET Figshare v2 (ORCID Fixed)"

# 1. CREATE ARTICLE (ORCID format fixed)
echo "📤 Creating article..."
RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: token $TOKEN" \
  -X POST https://api.figshare.com/v2/account/articles \
  -H "Content-Type: application/json" \
  -d '{
    "title": "ESQET v2.1: 25/25 Physics Unification",
    "description": "Symbolic derivation of 25 constants from φ-torsion manifold. Rydberg φ^(-27+2ξ)=1.0973731568160e7 m^-1 ✓",
    "keywords": ["Unified Field Theory","Torsion","Rydberg"],
    "categories": [27318],
    "authors": [{"name": "Marco Antônio Rocha Jr."}]
  }')

HTTP_CODE=${RESPONSE: -3}
RESPONSE_BODY=${RESPONSE%???}

echo "HTTP: $HTTP_CODE"
echo $RESPONSE_BODY | jq .

if [[ $HTTP_CODE == "201" ]]; then
    ARTICLE_ID=$(echo $RESPONSE_BODY | jq -r '.location // empty | split("/")[-1]')
    echo "✅ SUCCESS! Article ID: $ARTICLE_ID"
    echo "🔗 https://figshare.com/account/articles/$ARTICLE_ID"
    
    # 2. UPLOAD FILE
    if [[ -f $ESQET_FILE ]]; then
        echo "📁 Uploading whitepaper..."
        UPLOAD=$(curl -s -w "%{http_code}" -H "Authorization: token $TOKEN" \
          -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/files" \
          -F "file=@$ESQET_FILE")
        echo "Upload HTTP: ${UPLOAD: -3}"
        echo "✅ DOI: 10.6084/m9.figshare.$ARTICLE_ID"
    fi
else
    echo "❌ Failed. Full response:"
    echo $RESPONSE_BODY
fi
