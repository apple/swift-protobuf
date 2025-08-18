# Releasing Swift Protobuf

---

This document covers two types of releases:

1. **Swift Protobuf Library Releases** - New versions of the Swift protobuf library itself
2. **Protoc Artifactbundle Releases** - Updates to the bundled protoc compiler when new protoc versions are available

## Swift Protobuf Library Releases

When doing a Swift Protobuf library release:

1. Examine what has changed

   Github's compare UI does a reasonable job here.  [Open that UI](https://github.com/apple/swift-protobuf/compare)
   and set the _base_ to be the previous tag (_X.Y.Z_), and the _compare_ can be left at _main_
   since that is what the release is cut off of.

   It usually works best to open the links for each commit you want to look at in a new browser
   window/tab.  That way you can review each independently rather then looking at the unified
   diffs.

   When looking at a individual commit, at the top github will show that it was a commit on main
   and include a reference '#XYZ', this tells you what pull request it was part of.  This is useful
   for doing the release notes in the next section.

1. Update the version on _main_

   ```
   DevTools/LibraryVersions.py [a.b.c]
   ```

   If you aren't sure if `b` or `c`, rather then checking all the _semver_ tags on the
   PRs, you can use the [project's releases page](https://github.com/apple/swift-protobuf/releases)
   and _Draft a new release_; fill in _99.99_ for that tag, and then click the _Generate
   release notes_ button, it will include sections based on the _semver_ tags to indicate
   which segment *must* be updated. If you do this *discard* this draft as you don't
   actually want to create a _99.99_ release later on.

   _Note:__ `a` is really rare since it is a major version bump usually reserved for
   breaking changes as it has a cost on all things that depend on this repo.

   *Import* Make sure to commit/merge this _main_ on github.

1. Create a release on github

   Top left of the [project's releases page](https://github.com/apple/swift-protobuf/releases)
   is _Draft a new release_.

   The tag should be `[a.b.c]` where the number *exactly* matches one you used in the
   previous step (and just committed to the repo).

   For the description click the _Generate release notes_ button. That should do
   everything based on the PR descriptions and _semver_ tags in the repo. Just read
   though was was generate to see if any tweaks are needed.
   
   *Important* Ensure that the `Set as the latest release` is checked.

1. Publish the `SwiftProtobuf.podspec`

      _Note:_ You must be an _owner_ of the pod to do this, see `pod trunk info SwiftProtobuf`
      for who are owners.

      ```
      pod trunk push SwiftProtobuf.podspec
      ```

      _Note:_ This uses that local copy of `SwiftProtobuf.podspec`, but checks
      against the sources on github.

## Protoc Artifactbundle Releases

Protoc artifactbundle releases are independent of Swift Protobuf library releases and follow 
a `protoc-vX.Y` naming convention that matches the upstream protoc version.

### Creating a protoc release

1. **Trigger the workflow**

   Go to the [Actions tab](https://github.com/apple/swift-protobuf/actions/workflows/draft_release_protoc_artifactbundle.yml)
   and manually run the "Draft release protoc artifactbundle" workflow.

2. **What the workflow does automatically**

   The workflow will:
   - Check the latest protoc version from protocolbuffers/protobuf
   - Check if we already have a matching `protoc-vX.Y` release
   - If versions differ or no release exists:
     - Download protoc binaries for all supported platforms
     - Create a Swift Package Manager compatible artifact bundle
     - Create a new draft release tagged `protoc-vX.Y`
     - Upload the artifactbundle to the draft release
   - If versions match, exit early (no action needed)

3. **Publish the release**

   After the workflow completes successfully:
   - Go to the [releases page](https://github.com/apple/swift-protobuf/releases)
   - Find the draft `protoc-vX.Y` release
   - Review the release notes and artifactbundle
   - Click "Publish release"

4. **Use in Swift Protobuf**

   The protoc release is now available with a stable URL that can be referenced
   in `Package.swift`. Create a separate PR to update the reference in the `Package.swift`
