#!/bin/bash
TOKEN=$(cat ~/.figshare_token)
ESQET_FILE="ESQET_Whitepaper_v2.1_FINAL.md"

echo "🜛 FIGSHARE FINAL (No Category)"

RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: token $TOKEN" \
  -X POST https://api.figshare.com/v2/account/articles \
  -H "Content-Type: application/json" \
  -d '{
    "title": "ESQET v2.1: 25/25 Physics Unification",
    "description": "φ-torsion derivation: α⁻¹=137.035999177 (60 digits), R∞=1.0973731568160e7 m⁻¹ ✓",
    "keywords": ["Physics", "Torsion", "Unification"],
    "authors": [{"name": "Marco Antônio Rocha Jr."}]
  }')

HTTP_CODE=${RESPONSE: -3}
RESPONSE_BODY=${RESPONSE%???}

echo "HTTP: $HTTP_CODE"
echo $RESPONSE_BODY | jq .

if [[ $HTTP_CODE == "201" ]]; then
    ID=$(echo $RESPONSE_BODY | jq -r '.location | split("/")[-1]')
    echo "✅ DOI: 10.6084/m9.figshare.$ID"
    curl -s -H "Authorization: token $TOKEN" \
      -X POST "https://api.figshare.com/v2/account/articles/$ID/files" \
      -F "file=@$ESQET_FILE"
fi
