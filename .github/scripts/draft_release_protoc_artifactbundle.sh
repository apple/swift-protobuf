#!/bin/bash

# This script generates an artifactbundle for protoc. This artifactbundle
# is used by the Swift package manger. The script is run by a GitHub action
# to create protoc-vXXX releases with artifactbundles.

set -eux

AUTH="Authorization: token $GITHUB_TOKEN"

# Fetch the latest stable release from protocolbuffers/protobuf
upstream_response=$(curl -sH "$AUTH" "https://api.github.com/repos/protocolbuffers/protobuf/releases/latest")
TAG=$(echo "$upstream_response" | grep -m 1 '"tag_name":' | cut -d '"' -f 4)

# Remove 'v' prefix if present
TAG="${TAG#v}"

if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: $TAG does not match the expected pattern"
    exit 1
fi

echo "Latest upstream protoc version: $TAG"

# Check for the latest protoc-vXXX release in this swift-protobuf repo
swift_protobuf_response=$(curl -sH "$AUTH" "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases")
CURRENT_PROTOC_TAG=$(echo "$swift_protobuf_response" | jq -r '.[] | select(.tag_name | startswith("protoc-v")) | .tag_name' | head -n 1)

if [ -z "$CURRENT_PROTOC_TAG" ] || [ "$CURRENT_PROTOC_TAG" = "null" ]; then
    echo "No existing protoc-vXXX release found. This will be the initial release."
    CURRENT_PROTOC_VERSION=""
else
    # Extract version from protoc-vX.Y format
    CURRENT_PROTOC_VERSION="${CURRENT_PROTOC_TAG#protoc-v}"
    echo "Current swift-protobuf protoc version: $CURRENT_PROTOC_VERSION"
fi

# Compare versions - if they match, no need to create a new release
if [ "$CURRENT_PROTOC_VERSION" = "$TAG" ]; then
    echo "Protoc version $TAG is already released. No action needed."
    exit 0
fi

echo "Creating new protoc release: protoc-v$TAG"

# Fetch all protoc release assets from protocolbuffers/protobuf
curl -LJ --output protoc-$TAG-osx-x86_64.zip -H 'Accept: application/octet-stream' https://github.com/protocolbuffers/protobuf/releases/download/v$TAG/protoc-$TAG-osx-x86_64.zip
curl -LJ --output protoc-$TAG-osx-aarch_64.zip -H 'Accept: application/octet-stream' https://github.com/protocolbuffers/protobuf/releases/download/v$TAG/protoc-$TAG-osx-aarch_64.zip
curl -LJ --output protoc-$TAG-linux-aarch_64.zip -H 'Accept: application/octet-stream' https://github.com/protocolbuffers/protobuf/releases/download/v$TAG/protoc-$TAG-linux-aarch_64.zip
curl -LJ --output protoc-$TAG-linux-x86_64.zip -H 'Accept: application/octet-stream' https://github.com/protocolbuffers/protobuf/releases/download/v$TAG/protoc-$TAG-linux-x86_64.zip
curl -LJ --output protoc-$TAG-win64.zip -H 'Accept: application/octet-stream' https://github.com/protocolbuffers/protobuf/releases/download/v$TAG/protoc-$TAG-win64.zip

# Fetch and validate license from protocolbuffers/protobuf
curl -LJ --output LICENSE -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/protocolbuffers/protobuf/contents/LICENSE
LICENSE_HASH=$(sha256sum LICENSE | cut -d ' ' -f 1)
EXPECTED_HASH="6e5e117324afd944dcf67f36cf329843bc1a92229a8cd9bb573d7a83130fea7d"

if [ "$LICENSE_HASH" != "$EXPECTED_HASH" ]; then
    echo "Error: License file has changed. Expected hash: $EXPECTED_HASH, Got: $LICENSE_HASH"
    exit 1
fi

# Unzip all assets
mkdir protoc-$TAG.artifactbundle
unzip -d protoc-$TAG.artifactbundle/protoc-$TAG-osx-x86_64 protoc-$TAG-osx-x86_64.zip
unzip -d protoc-$TAG.artifactbundle/protoc-$TAG-osx-aarch_64 protoc-$TAG-osx-aarch_64.zip
unzip -d protoc-$TAG.artifactbundle/protoc-$TAG-linux-aarch_64 protoc-$TAG-linux-aarch_64.zip
unzip -d protoc-$TAG.artifactbundle/protoc-$TAG-linux-x86_64 protoc-$TAG-linux-x86_64.zip
unzip -d protoc-$TAG.artifactbundle/protoc-$TAG-win64 protoc-$TAG-win64.zip

# Copy license file into artifactbundle
cp LICENSE protoc-$TAG.artifactbundle/

# Create info.json for artifactbundle
cat > protoc-$TAG.artifactbundle/info.json << EOF
{
    "schemaVersion": "1.0",
    "artifacts": {
        "protoc": {
            "type": "executable",
            "version": "$TAG",
            "variants": [
                {
                    "path": "protoc-$TAG-linux-x86_64/bin/protoc",
                    "supportedTriples": ["x86_64-unknown-linux-gnu"]
                },
                {
                    "path": "protoc-$TAG-linux-aarch_64/bin/protoc",
                    "supportedTriples": ["aarch64-unknown-linux-gnu", "arm64-unknown-linux-gnu", "aarch64-unknown-linux", "arm64-unknown-linux"]
                },
                {
                    "path": "protoc-$TAG-osx-x86_64/bin/protoc",
                    "supportedTriples": ["x86_64-apple-macosx"]
                },
                {
                    "path": "protoc-$TAG-osx-aarch_64/bin/protoc",
                    "supportedTriples": ["arm64-apple-macosx"]
                },
                {
                    "path": "protoc-$TAG-win64/bin/protoc.exe",
                    "supportedTriples": ["x86_64-unknown-windows"]
                },
            ]
        }
    }
}
EOF

# Zip artifactbundle
zip -r protoc-$TAG.artifactbundle.zip protoc-$TAG.artifactbundle

# Create a new draft release for protoc-vXXX
echo "Creating draft release protoc-v$TAG"
create_response=$(curl -sH "$AUTH" -X POST "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases" \
  -d "{
    \"tag_name\": \"protoc-artifactbundle-v$TAG\",
    \"name\": \"protoc v$TAG artifactbundle\",
    \"body\": \"Protoc artifactbundle for version $TAG\",
    \"draft\": true,
    \"prerelease\": false,
    \"make_latest\": \"false\"
  }")

upload_url=$(echo "$create_response" | jq -r '.upload_url')
release_id=$(echo "$create_response" | jq -r '.id')

if [ -z "$upload_url" ] || [ "$upload_url" = "null" ] || [ -z "$release_id" ] || [ "$release_id" = "null" ]; then
    echo "Error: Failed to create draft release"
    echo "Response: $create_response"
    exit 1
fi

# Remove the {?name,label} template from upload_url
upload_url=$(echo "$upload_url" | sed 's/{?name,label}//')
echo "Created draft release with ID: $release_id"
echo "Upload URL: $upload_url"

# Upload asset
echo "Uploading artifactbundle..."
upload_response=$(curl --data-binary @protoc-$TAG.artifactbundle.zip -H "$AUTH" -H "Content-Type: application/octet-stream" "$upload_url?name=protoc-$TAG.artifactbundle.zip")

echo "Upload completed successfully!"
echo "Draft release protoc-v$TAG created with artifactbundle"
