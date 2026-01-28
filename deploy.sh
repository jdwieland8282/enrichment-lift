#!/bin/bash

# ================================
# Enrichment Lift: Clean Deploy Script
# ================================

# Exit on errors
set -e

# 1. Build the dist folder
echo "Building dist folder..."
rm -rf dist
mkdir dist
cp -r index.html prebid.js assets vendors scripts dist/

# 2. Create temporary folder for clean deploy
TMP_DEPLOY=$(mktemp -d)
echo "Using temporary folder: $TMP_DEPLOY"

# 3. Copy dist contents to temp folder
cp -r dist/* "$TMP_DEPLOY/"

# 4. Go to temp folder
cd "$TMP_DEPLOY"

# 5. Initialize git, add all files, commit
git init
git add .
git commit -m "Deploy Enrichment Lift demo"

# 6. Add remote and force push to gh-pages
git branch -M gh-pages
git remote add origin https://github.com/jdwieland8282/enrichment-lift.git
git push -f origin gh-pages

echo "Deployment complete! Your site should be live at:"
echo "https://jdwieland8282.github.io/enrichment-lift/"

# 7. Clean up
cd -
rm -rf "$TMP_DEPLOY"
