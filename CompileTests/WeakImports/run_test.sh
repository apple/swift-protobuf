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
  "${SWIFT}" build --package-path "${REPO_ROOT}" -c release --product SwiftProtobuf
fi
SWIFT_BIN_DIR="$("${SWIFT}" build --package-path "${REPO_ROOT}" -c release --show-bin-path)"

echo "==> Compiling ModuleB..."
"${SWIFTC}" -O -parse-as-library \
  -module-name ModuleB \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleB.swiftmodule" \
  -I "${SWIFT_BIN_DIR}" \
  -Xfrontend -internalize-at-link \
  -c "${SCRIPT_DIR}/Sources/ModuleB/b.pb.swift" \
  -o "${BUILD_DIR}/ModuleB.o"
ar cr "${BUILD_DIR}/libModuleB.a" "${BUILD_DIR}/ModuleB.o"
ranlib "${BUILD_DIR}/libModuleB.a"

echo "==> Compiling ModuleC..."
"${SWIFTC}" -O -parse-as-library \
  -module-name ModuleC \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleC.swiftmodule" \
  -I "${SWIFT_BIN_DIR}" \
  -Xfrontend -internalize-at-link \
  -c "${SCRIPT_DIR}/Sources/ModuleC/c.pb.swift" \
  -o "${BUILD_DIR}/ModuleC.o"
ar cr "${BUILD_DIR}/libModuleC.a" "${BUILD_DIR}/ModuleC.o"
ranlib "${BUILD_DIR}/libModuleC.a"

echo "==> Compiling ModuleA..."
"${SWIFTC}" -O -parse-as-library \
  -module-name ModuleA \
  -emit-module -emit-module-path "${BUILD_DIR}/ModuleA.swiftmodule" \
  -I "${SWIFT_BIN_DIR}" \
  -I "${BUILD_DIR}" \
  -Xfrontend -internalize-at-link \
  -c "${SCRIPT_DIR}/Sources/ModuleA/a.pb.swift" \
  -o "${BUILD_DIR}/ModuleA.o"
ar cr "${BUILD_DIR}/libModuleA.a" "${BUILD_DIR}/ModuleA.o"
ranlib "${BUILD_DIR}/libModuleA.a"

echo "==> Compiling Client..."
"${SWIFTC}" -O -parse-as-library \
  -module-name Client \
  -I "${SWIFT_BIN_DIR}" \
  -I "${BUILD_DIR}" \
  -Xfrontend -internalize-at-link \
  -c "${SCRIPT_DIR}/Sources/Client/Client.swift" \
  -o "${BUILD_DIR}/Client.o"

echo "==> Linking Client..."
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

LINK_LIBS=(
  "${BUILD_DIR}/libModuleA.a"
  "${BUILD_DIR}/libModuleB.a"
  "${BUILD_DIR}/libModuleC.a"
  "${SWIFT_BIN_DIR}/libSwiftProtobuf.a"
)

"${SWIFTC}" "${BUILD_DIR}/Client.o" \
  "${LINK_LIBS[@]}" \
  "${LINK_FLAGS[@]}" \
  -o "${BUILD_DIR}/Client"

echo "==> Running Client..."
"${BUILD_DIR}/Client"

echo "==> Verifying symbols..."
set +e
python3 "${SCRIPT_DIR}/check_symbols.py" \
  --binary "${BUILD_DIR}/Client" \
  --check-file "${SCRIPT_DIR}/Sources/Client/Client.swift"
SYMBOL_CHECK_STATUS=$?
set -e

if [ $SYMBOL_CHECK_STATUS -ne 0 ]; then
  echo "⚠️ Symbol check exited with status ${SYMBOL_CHECK_STATUS}."
  exit $SYMBOL_CHECK_STATUS
fi
