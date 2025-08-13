#!/bin/bash

# This script generates an artifactbundle for protoc. This artifactbundle
# is used by the Swift package manger. The script is run by a GitHub action
# when a new pre-release is created for swift-protobuf.

set -eux

# Fetch the latest stable release from protocolbuffers/protobuf
AUTH="Authorization: token $GITHUB_TOKEN"
response=$(curl -sH "$AUTH" "https://api.github.com/repos/protocolbuffers/protobuf/releases/latest")
TAG=$(echo "$response" | grep -m 1 '"tag_name":' | cut -d '"' -f 4)

# Remove 'v' prefix if present
TAG="${TAG#v}"

if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: $TAG does not match the expected pattern"
    exit 1
fi

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

# Get asset upload url for the latest swift-protobuf draft release
response=$(curl -sH "$AUTH" "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases")
upload_url=$(echo "$response" | jq -r '.[] | select(.draft == true) | .upload_url' | head -n 1)
SWIFT_PROTOBUF_TAG=$(echo "$response" | jq -r '.[] | select(.draft == true) | .tag_name' | head -n 1)

if [ -z "$SWIFT_PROTOBUF_TAG" ] || [ -z "$upload_url" ]; then
    echo "Error: No draft release found"
    exit 1
fi

# Remove the {?name,label} template from upload_url
upload_url=$(echo "$upload_url" | sed 's/{?name,label}//')
echo "Found draft release: $SWIFT_PROTOBUF_TAG"
echo "Upload URL: $upload_url"

# Upload asset
curl --data-binary @protoc-$TAG.artifactbundle.zip -H "$AUTH" -H "Content-Type: application/octet-stream" "$upload_url?name=protoc-$TAG.artifactbundle.zip"
