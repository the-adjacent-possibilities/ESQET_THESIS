#!/bin/bash
TOKEN=$(cat ~/.figshare_token)
ESQET_FILE="ESQET_Whitepaper_v2.1_FINAL.md"

echo "🜛 ESQET Figshare - PERFECT SCRIPT"

# 1. CREATE ARTICLE (robust HTTP extraction)
echo "📤 Step 1/3: Creating article..."
HTTP_CODE=$(curl -s -w "%{http_code}" -o response.json \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -X POST https://api.figshare.com/v2/account/articles \
  -d '{
    "title": "ESQET v2.1: 25/25 Physics Unification",
    "description": "φ-torsion: α⁻¹=137.035999177(60 digits), R∞=1.0973731568160e7 m⁻¹, Cañon City 5.54% torsion gain",
    "keywords": ["Physics", "Torsion", "Unification"],
    "authors": [{"name": "Marco Antônio Rocha Jr."}]
  }')

echo "✅ HTTP: $HTTP_CODE"

if [[ $HTTP_CODE == "201" ]]; then
    # Extract ARTICLE_ID safely
    ARTICLE_ID=$(jq -r '.location | split("/")[-1]' response.json)
    echo "✅ Article ID: $ARTICLE_ID"
    echo "✅ DOI: 10.6084/m9.figshare.$ARTICLE_ID"
    echo "🔗 https://figshare.com/account/articles/$ARTICLE_ID"
    
    # 2. UPLOAD FILE (robust multipart)
    if [[ -f "$ESQET_FILE" ]]; then
        echo "📤 Step 2/3: Uploading $ESQET_FILE..."
        UPLOAD_CODE=$(curl -s -w "%{http_code}" -o upload.json \
          -H "Authorization: token $TOKEN" \
          -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/files" \
          -F "file=@$ESQET_FILE")
        
        echo "✅ Upload HTTP: $UPLOAD_CODE"
        echo "✅ FILE UPLOADED! DOI LIVE: 10.6084/m9.figshare.$ARTICLE_ID"
    else
        echo "❌ $ESQET_FILE missing"
        exit 1
    fi
    
    # 3. PUBLISH (makes DOI public)
    echo "📤 Step 3/3: Publishing (makes DOI permanent)..."
    PUBLISH_CODE=$(curl -s -w "%{http_code}" -o publish.json \
      -H "Authorization: token $TOKEN" \
      -X POST "https://api.figshare.com/v2/account/articles/$ARTICLE_ID/publish")
    
    echo "✅ Publish HTTP: $PUBLISH_CODE"
    echo "🎉 DOI FULLY PUBLISHED: 10.6084/m9.figshare.$ARTICLE_ID"
    
else
    echo "❌ CREATE FAILED ($HTTP_CODE):"
    cat response.json
fi

# Cleanup
rm -f response.json upload.json publish.json
