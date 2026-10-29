#!/bin/bash
#
# Builds and runs the WeakImports test client using by invoking the compiler and
# linker directly and using static libraries, verifying behavior in a setting
# similar to what a Bazel build would look like.
#
# This is important because using weak linking to drop as many unreferenced
# symbols as possible also relies on the linker not loading any object files
# from archives if no symbols from those object files are referenced from the
# application. Swift Package Manager doesn't use static libraries -- it passes
# all object files to the linker directly -- which circumvents this behavior.
# (We acknowledge that this means that single-threaded whole-module-optimization
# would also share the same fate.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SWIFT="${SWIFT:-swift}"
SWIFTC="${SWIFTC:-swiftc}"

BUILD_DIR="${SCRIPT_DIR}/.build/direct"

WHYLOAD=false
SKIP_BUILD_RUNTIME=false

for arg in "$@"; do
  case "$arg" in
    --whyload)
      WHYLOAD=true
      ;;
    --skip-build-runtime)
      SKIP_BUILD_RUNTIME=true
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --whyload              Pass -whyload to the linker (Darwin only)"
      echo "  --skip-build-runtime   Skip rebuilding the SwiftProtobuf runtime"
      exit 0
      ;;
  esac
done

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

if [ "${SKIP_BUILD_RUNTIME}" = false ]; then
  echo "==> Building SwiftProtobuf runtime..."
  "${SWIFT}" build --package-path "${REPO_ROOT}" -c release --product SwiftProtobuf \
    -Xswiftc -Xfrontend -Xswiftc -internalize-at-link
fi
SWIFT_BIN_DIR="$("${SWIFT}" build --package-path "${REPO_ROOT}" -c release --show-bin-path)"

# SwiftPM with llbuild (such as Swift 6.3 on Linux) places .swiftmodule files in
# a `Modules` subdirectory of the bin path, whereas SwiftBuild (Swift 6.4+ on
# Linux, and Xcode build system on Darwin) places them directly in the bin path.
SWIFT_INCLUDES=(-I "${SWIFT_BIN_DIR}")
if [ -d "${SWIFT_BIN_DIR}/Modules" ]; then
  SWIFT_INCLUDES+=(-I "${SWIFT_BIN_DIR}/Modules")
fi

SWIFT_FRONTEND_FLAGS=(
  -swift-version 6
  -Xfrontend -internalize-at-link
  -Xfrontend -disable-reflection-metadata
  -Xfrontend -disable-reflection-names
)

echo "==> Compiling ModuleB..."
"${SWIFTC}" -O -parse-as-library \
  -working-directory "${BUILD_DIR}" \
  -module-name ModuleB \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleB.swiftmodule" \
  "${SWIFT_INCLUDES[@]}" \
  "${SWIFT_FRONTEND_FLAGS[@]}" \
  -c "${SCRIPT_DIR}/Sources/ModuleB/b.pb.swift" \
     "${SCRIPT_DIR}/Sources/ModuleB/b.pbschema.swift"
ar cr "${BUILD_DIR}/libModuleB.a" "${BUILD_DIR}/b.pb.o" "${BUILD_DIR}/b.pbschema.o"
ranlib "${BUILD_DIR}/libModuleB.a"

echo "==> Compiling ModuleC..."
"${SWIFTC}" -O -parse-as-library \
  -working-directory "${BUILD_DIR}" \
  -module-name ModuleC \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleC.swiftmodule" \
  "${SWIFT_INCLUDES[@]}" \
  "${SWIFT_FRONTEND_FLAGS[@]}" \
  -c "${SCRIPT_DIR}/Sources/ModuleC/c.pb.swift" \
     "${SCRIPT_DIR}/Sources/ModuleC/c.pbschema.swift"
ar cr "${BUILD_DIR}/libModuleC.a" "${BUILD_DIR}/c.pb.o" "${BUILD_DIR}/c.pbschema.o"
ranlib "${BUILD_DIR}/libModuleC.a"

echo "==> Compiling ModuleA..."
"${SWIFTC}" -O -parse-as-library \
  -working-directory "${BUILD_DIR}" \
  -module-name ModuleA \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleA.swiftmodule" \
  "${SWIFT_INCLUDES[@]}" \
  -I "${BUILD_DIR}" \
  "${SWIFT_FRONTEND_FLAGS[@]}" \
  -c "${SCRIPT_DIR}/Sources/ModuleA/a.pb.swift" \
     "${SCRIPT_DIR}/Sources/ModuleA/a.pbschema.swift"
ar cr "${BUILD_DIR}/libModuleA.a" "${BUILD_DIR}/a.pb.o" "${BUILD_DIR}/a.pbschema.o"
ranlib "${BUILD_DIR}/libModuleA.a"

OS="$(uname -s)"
LINK_FLAGS=()
if [ "$OS" = "Darwin" ]; then
  LINK_FLAGS+=(
    -Xlinker -dead_strip
    -Xlinker -undefined -Xlinker dynamic_lookup
  )
  if [ "${WHYLOAD}" = true ]; then
    LINK_FLAGS+=(-Xlinker -whyload)
  fi
elif [ "$OS" = "Linux" ]; then
  LINK_FLAGS+=(
    -Xlinker -export-dynamic
    -Xlinker --unresolved-symbols=ignore-in-object-files
  )
fi

SWIFT_PROTOBUF_LIB="${SWIFT_BIN_DIR}/libSwiftProtobuf.a"
if [ ! -f "${SWIFT_PROTOBUF_LIB}" ]; then
  # SwiftPM with llbuild (such as Swift 6.3 on Linux) does not package automatic
  # library products into static archives; it leaves object files loose in the
  # target build directory. Package them into a static archive manually.
  SWIFT_PROTOBUF_LIB="${BUILD_DIR}/libSwiftProtobuf.a"
  SWIFT_PROTOBUF_OBJECTS=()
  while IFS= read -r -d '' obj; do
    SWIFT_PROTOBUF_OBJECTS+=("${obj}")
  done < <(find "${SWIFT_BIN_DIR}" -path "*/SwiftProtobuf.build/*.o" -print0)
  if [ ${#SWIFT_PROTOBUF_OBJECTS[@]} -eq 0 ]; then
    while IFS= read -r -d '' obj; do
      SWIFT_PROTOBUF_OBJECTS+=("${obj}")
    done < <(find "${REPO_ROOT}/.build" -not -path "*/index-build/*" -path "*/SwiftProtobuf.build/*.o" -print0)
  fi
  if [ ${#SWIFT_PROTOBUF_OBJECTS[@]} -eq 0 ]; then
    echo "error: Could not find SwiftProtobuf object files to create archive" >&2
    exit 1
  fi
  ar cr "${SWIFT_PROTOBUF_LIB}" "${SWIFT_PROTOBUF_OBJECTS[@]}"
  ranlib "${SWIFT_PROTOBUF_LIB}"
fi

LINK_LIBS=(
  "${BUILD_DIR}/libModuleA.a"
  "${BUILD_DIR}/libModuleB.a"
  "${BUILD_DIR}/libModuleC.a"
  "${SWIFT_PROTOBUF_LIB}"
)

CLIENTS=(
  "Client"
  "TextFormatClient"
  "JSONClient"
  "FieldMaskClient"
)

for CLIENT in "${CLIENTS[@]}"; do
  echo "==> Compiling ${CLIENT}..."
  "${SWIFTC}" -O -parse-as-library \
    -module-name "${CLIENT}" \
    "${SWIFT_INCLUDES[@]}" \
    -I "${BUILD_DIR}" \
    "${SWIFT_FRONTEND_FLAGS[@]}" \
    -c "${SCRIPT_DIR}/Sources/${CLIENT}/${CLIENT}.swift" \
    -o "${BUILD_DIR}/${CLIENT}.o"

  echo "==> Linking ${CLIENT}..."
  "${SWIFTC}" "${BUILD_DIR}/${CLIENT}.o" \
    "${LINK_LIBS[@]}" \
    "${LINK_FLAGS[@]}" \
    -o "${BUILD_DIR}/${CLIENT}"

  echo "==> Running ${CLIENT}..."
  "${BUILD_DIR}/${CLIENT}"

  echo "==> Verifying symbols in ${CLIENT}..."
  set +e
  python3 "${SCRIPT_DIR}/check_symbols.py" \
    --binary "${BUILD_DIR}/${CLIENT}" \
    --check-file "${SCRIPT_DIR}/Sources/${CLIENT}/${CLIENT}.swift"
  SYMBOL_CHECK_STATUS=$?
  set -e

  if [ $SYMBOL_CHECK_STATUS -ne 0 ]; then
    echo "⚠️ Symbol check for ${CLIENT} exited with status ${SYMBOL_CHECK_STATUS}."
    exit $SYMBOL_CHECK_STATUS
  fi
done
