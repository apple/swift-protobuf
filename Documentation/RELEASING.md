# Releasing Swift Protobuf

---

This document covers two types of releases:

1. **Swift Protobuf Library Releases** - New versions of the Swift protobuf library itself
2. **Updating Protobuf and Abseil Submodules** - Updates the git submodules used to build `protoc` to the latest release.

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

   _Note:_ `a` is really rare since it is a major version bump usually reserved for
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

## Updating Protobuf and Abseil Submodules

The swift-protobuf repository uses git submodules for protobuf and abseil-cpp dependencies.

### Automatic Updates (Recommended)

The repository has an automated workflow that checks for new protobuf releases **every night at 2am UTC**.
When a new release is detected, the workflow will:

1. Update the protobuf submodule to the latest release tag
2. Determine the required abseil-cpp version from protobuf's `protobuf_deps.bzl`
3. Update the abseil-cpp submodule accordingly
4. Create a pull request with the changes

The workflow can also be triggered manually from the [Actions tab](https://github.com/apple/swift-protobuf/actions/workflows/update_protobuf.yml).

**No manual intervention is typically required** - just review and merge the automated PR after CI passes.

### Manual Updates (If Needed)

If you need to update the submodules manually (e.g., to test a pre-release version), follow these steps:

1. **Check for new protobuf releases**

   Visit the [protobuf releases page](https://github.com/protocolbuffers/protobuf/releases)
   to check if a new version is available.

1. **Update the protobuf submodule**

   From the repository root, update the protobuf submodule to the latest release tag:

   ```bash
   cd Sources/protobuf/protobuf
   git fetch --tags
   git checkout vX.Y.Z  # Replace with the actual release tag, e.g., v29.2
   cd ../../..
   git add Sources/protobuf/protobuf
   ```

1. **Check the abseil-cpp version**

   The protobuf library depends on a specific version of abseil-cpp. Check which version
   is required by examining `Sources/protobuf/protobuf/protobuf_deps.bzl`:

   ```bash
   grep -A 3 "abseil-cpp" Sources/protobuf/protobuf/protobuf_deps.bzl
   ```

   Look for the `commit` field in the abseil-cpp section to find the required commit hash.

1. **Update the abseil-cpp submodule**

   Update the abseil-cpp submodule to match the version required by protobuf:

   ```bash
   cd Sources/protobuf/abseil
   git fetch
   git checkout <commit-hash>  # Use the commit from protobuf_deps.bzl
   cd ../../..
   git add Sources/protobuf/abseil
   ```

1. **Create a pull request**

   Commit the submodule updates and create a PR:

   ```bash
   git commit -m "Update protobuf submodule to vX.Y.Z and abseil-cpp to <version>"
   git push origin <your-branch>
   ```

   In the PR description, include:
   - The protobuf version being updated to
   - The abseil-cpp version/commit being updated to
   - Any relevant release notes from the protobuf release
