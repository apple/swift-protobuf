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
license_response=$(curl "https://api.github.com/repos/protocolbuffers/protobuf/contents/LICENSE")
LICENSE_CONTENT=$(echo "$license_response" | jq -r '.content' | tr -d '\n')
EXPECTED_CONTENT="Q29weXJpZ2h0IDIwMDggR29vZ2xlIEluYy4gIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgpSZWRpc3RyaWJ1dGlvbiBhbmQgdXNlIGluIHNvdXJjZSBhbmQgYmluYXJ5IGZvcm1zLCB3aXRoIG9yIHdpdGhvdXQKbW9kaWZpY2F0aW9uLCBhcmUgcGVybWl0dGVkIHByb3ZpZGVkIHRoYXQgdGhlIGZvbGxvd2luZyBjb25kaXRpb25zIGFyZQptZXQ6CgogICAgKiBSZWRpc3RyaWJ1dGlvbnMgb2Ygc291cmNlIGNvZGUgbXVzdCByZXRhaW4gdGhlIGFib3ZlIGNvcHlyaWdodApub3RpY2UsIHRoaXMgbGlzdCBvZiBjb25kaXRpb25zIGFuZCB0aGUgZm9sbG93aW5nIGRpc2NsYWltZXIuCiAgICAqIFJlZGlzdHJpYnV0aW9ucyBpbiBiaW5hcnkgZm9ybSBtdXN0IHJlcHJvZHVjZSB0aGUgYWJvdmUKY29weXJpZ2h0IG5vdGljZSwgdGhpcyBsaXN0IG9mIGNvbmRpdGlvbnMgYW5kIHRoZSBmb2xsb3dpbmcgZGlzY2xhaW1lcgppbiB0aGUgZG9jdW1lbnRhdGlvbiBhbmQvb3Igb3RoZXIgbWF0ZXJpYWxzIHByb3ZpZGVkIHdpdGggdGhlCmRpc3RyaWJ1dGlvbi4KICAgICogTmVpdGhlciB0aGUgbmFtZSBvZiBHb29nbGUgSW5jLiBub3IgdGhlIG5hbWVzIG9mIGl0cwpjb250cmlidXRvcnMgbWF5IGJlIHVzZWQgdG8gZW5kb3JzZSBvciBwcm9tb3RlIHByb2R1Y3RzIGRlcml2ZWQgZnJvbQp0aGlzIHNvZnR3YXJlIHdpdGhvdXQgc3BlY2lmaWMgcHJpb3Igd3JpdHRlbiBwZXJtaXNzaW9uLgoKVEhJUyBTT0ZUV0FSRSBJUyBQUk9WSURFRCBCWSBUSEUgQ09QWVJJR0hUIEhPTERFUlMgQU5EIENPTlRSSUJVVE9SUwoiQVMgSVMiIEFORCBBTlkgRVhQUkVTUyBPUiBJTVBMSUVEIFdBUlJBTlRJRVMsIElOQ0xVRElORywgQlVUIE5PVApMSU1JVEVEIFRPLCBUSEUgSU1QTElFRCBXQVJSQU5USUVTIE9GIE1FUkNIQU5UQUJJTElUWSBBTkQgRklUTkVTUyBGT1IKQSBQQVJUSUNVTEFSIFBVUlBPU0UgQVJFIERJU0NMQUlNRUQuIElOIE5PIEVWRU5UIFNIQUxMIFRIRSBDT1BZUklHSFQKT1dORVIgT1IgQ09OVFJJQlVUT1JTIEJFIExJQUJMRSBGT1IgQU5ZIERJUkVDVCwgSU5ESVJFQ1QsIElOQ0lERU5UQUwsClNQRUNJQUwsIEVYRU1QTEFSWSwgT1IgQ09OU0VRVUVOVElBTCBEQU1BR0VTIChJTkNMVURJTkcsIEJVVCBOT1QKTElNSVRFRCBUTywgUFJPQ1VSRU1FTlQgT0YgU1VCU1RJVFVURSBHT09EUyBPUiBTRVJWSUNFUzsgTE9TUyBPRiBVU0UsCkRBVEEsIE9SIFBST0ZJVFM7IE9SIEJVU0lORVNTIElOVEVSUlVQVElPTikgSE9XRVZFUiBDQVVTRUQgQU5EIE9OIEFOWQpUSEVPUlkgT0YgTElBQklMSVRZLCBXSEVUSEVSIElOIENPTlRSQUNULCBTVFJJQ1QgTElBQklMSVRZLCBPUiBUT1JUCihJTkNMVURJTkcgTkVHTElHRU5DRSBPUiBPVEhFUldJU0UpIEFSSVNJTkcgSU4gQU5ZIFdBWSBPVVQgT0YgVEhFIFVTRQpPRiBUSElTIFNPRlRXQVJFLCBFVkVOIElGIEFEVklTRUQgT0YgVEhFIFBPU1NJQklMSVRZIE9GIFNVQ0ggREFNQUdFLgoKQ29kZSBnZW5lcmF0ZWQgYnkgdGhlIFByb3RvY29sIEJ1ZmZlciBjb21waWxlciBpcyBvd25lZCBieSB0aGUgb3duZXIKb2YgdGhlIGlucHV0IGZpbGUgdXNlZCB3aGVuIGdlbmVyYXRpbmcgaXQuICBUaGlzIGNvZGUgaXMgbm90CnN0YW5kYWxvbmUgYW5kIHJlcXVpcmVzIGEgc3VwcG9ydCBsaWJyYXJ5IHRvIGJlIGxpbmtlZCB3aXRoIGl0LiAgVGhpcwpzdXBwb3J0IGxpYnJhcnkgaXMgaXRzZWxmIGNvdmVyZWQgYnkgdGhlIGFib3ZlIGxpY2Vuc2UuCg=="

if [ "$LICENSE_CONTENT" != "$EXPECTED_CONTENT" ]; then
    echo "Error: License file content has changed."
    exit 1
fi

# Decode and save the license file
echo "$LICENSE_CONTENT" | base64 -d > LICENSE

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
