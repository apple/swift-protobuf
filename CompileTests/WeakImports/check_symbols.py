#!/usr/bin/env python3
"""
Symbol verification tool for weak-imported Swift Protobuf tests.

This script verifies whether demangled symbols are present or absent in a
compiled binary based on LLVM FileCheck-like comment directives in a Swift
source file:

    // HAS-SYMBOL: ModuleName.SymbolName
    // HAS-SYMBOL-NOT: ModuleName.UnlinkedSymbolName

The name following the directive must match (or fail to match) the *whole*
symbol. Regular expressions can be embedded in the required match by wrapping
them with double curly braces `{{...}}`. For example,

    // HAS-SYMBOL: ModuleB.MessageB.{{.*}}
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile


def compile_pattern(pattern_str):
  """Compiles a match expression that might have FileCheck-like embedded regular expressions."""
  parts = []
  last_end = 0

  for m in re.finditer(r'\{\{(.*?)\}\}', pattern_str):
    # Escape literal text preceding the {{...}} block
    parts.append(re.escape(pattern_str[last_end:m.start()]))
    # Keep the raw regex expression inside {{...}}, wrapped in a non-capturing
    # group so alternation (|) doesn't leak into outer regex scope.
    parts.append(f"(?:{m.group(1)})")
    last_end = m.end()

  parts.append(re.escape(pattern_str[last_end:]))
  regex_str = "^" + "".join(parts) + "$"
  return re.compile(regex_str)


def detect_binary_format(binary_path):
  """Detects whether a binary is Mach-O or ELF based on magic bytes or OS fallback."""
  with open(binary_path, "rb") as f:
    magic = f.read(4)
    if magic == b"\x7fELF":
      return "ELF"
    # Mach-O 32-bit/64-bit (little-endian & big-endian) and Fat binary
    if magic in (b"\xfe\xed\xfa\xce", b"\xce\xfa\xed\xfe",
                  b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe",
                  b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"):
      return "MachO"

  import platform
  system = platform.system()
  if system == "Darwin":
    return "MachO"
  elif system == "Linux":
    return "ELF"
  return "Unknown"


def normalize_format(name):
  if not name:
    return None
  n = name.strip().lower().replace("-", "")
  if n in ("macho", "darwin", "apple"):
    return "MachO"
  if n in ("elf", "linux"):
    return "ELF"
  raise ValueError(f"Unknown object file format: '{name.strip()}'")


def parse_check_file(check_file_path, binary_format):
  """Extracts symbol match directives from the given file."""
  directives = []
  directive_re = re.compile(
      r"//\s*(HAS-SYMBOL(?:-NOT)?)(?:\s*\[\s*([a-zA-Z0-9_\-]+)\s+only\s*\])?\s*:\s*(.*)$"
  )
  with open(check_file_path, "r", encoding="utf-8") as f:
    for line_num, line in enumerate(f, start=1):
      line = line.strip()
      m = directive_re.search(line)
      if m:
        directive_type = m.group(1)
        format_cond = m.group(2)
        pattern_str = m.group(3).strip()

        display_directive = directive_type
        effective_type = directive_type

        if format_cond:
          display_directive = f"{directive_type} [{format_cond} only]"
          norm_cond = normalize_format(format_cond)
          if binary_format == norm_cond:
            effective_type = directive_type
          else:
            effective_type = "HAS-SYMBOL-NOT" if directive_type == "HAS-SYMBOL" else "HAS-SYMBOL"

        directives.append((
            line_num,
            effective_type,
            display_directive,
            pattern_str,
            compile_pattern(pattern_str),
        ))
  return directives


def extract_symbol_name(line):
  """Extracts the symbol name of a line of `nm` output.

  Supports both llvm-nm (Darwin/Mach-O) and GNU nm (Linux/ELF) output formats:
    - Darwin defined:   "000000010007de54 t SymbolName"
    - Darwin undefined: "                 U SymbolName"
    - GNU defined:      "0000000000001234 T SymbolName"
    - GNU undefined:    "                 U SymbolName" or "w SymbolName"
    - GNU with size:    "0000000000001234 0000000000000020 T SymbolName"
  """
  line = line.strip()
  if not line:
    return ""

  # GNU nm with address and size: "<addr> <size> <type> <symbol>"
  m = re.match(r"^[0-9a-fA-F]+\s+[0-9a-fA-F]+\s+([a-zA-Z?@\-])\s+(.+)$", line)
  if m:
    return m.group(2).strip()

  # Darwin or GNU nm without size: "[<addr>] <type> <symbol>"
  m = re.match(r"^(?:[0-9a-fA-F]+\s+)?([a-zA-Z?@\-])\s+(.+)$", line)
  if m:
    return m.group(2).strip()

  return line


def extract_demangled_symbols(binary_path):
  """Extracts the demangled Swift symbol names from the given executable."""
  try:
    nm_proc = subprocess.Popen(
      ["nm", binary_path],
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE)
    demangle_proc = subprocess.Popen(
      ["swift", "demangle"],
      stdin=nm_proc.stdout,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      text=True)
    nm_proc.stdout.close()
    out, err = demangle_proc.communicate()
    if demangle_proc.returncode != 0:
      sys.stderr.write(f"Error running swift demangle: {err}\n")
      sys.exit(1)
    return [extract_symbol_name(line) for line in out.splitlines() if line.strip()]
  except Exception as e:
    sys.stderr.write(f"Failed to extract demangled symbols from {binary_path}: {e}\n")
    sys.exit(1)


def main():
  parser = argparse.ArgumentParser(
      description="Verify symbol presence/absence in a compiled binary."
  )
  parser.add_argument(
      "--binary",
      required=True,
      help="Path to the compiled executable binary",
  )
  parser.add_argument(
      "--check-file",
      required=True,
      help="Path to the Swift source file containing directives",
  )
  parser.add_argument(
      "--format",
      choices=["MachO", "ELF"],
      help="Explicitly specify the binary format (default: auto-detected from binary)",
  )
  args = parser.parse_args()

  if not os.path.isfile(args.binary):
    sys.stderr.write(f"Error: Compiled binary file '{args.binary}' does not exist.\n")
    sys.exit(1)

  if not os.path.isfile(args.check_file):
    sys.stderr.write(f"Error: Check source file '{args.check_file}' does not exist.\n")
    sys.exit(1)

  binary_format = args.format or detect_binary_format(args.binary)
  directives = parse_check_file(args.check_file, binary_format)
  if not directives:
    print(f"Warning: No HAS-SYMBOL or HAS-SYMBOL-NOT directives found in '{args.check_file}'.")
    sys.exit(0)

  symbols = extract_demangled_symbols(args.binary)

  failed = False
  print(f"Checking symbols in {args.binary} ({binary_format}) against {args.check_file}...")

  GREEN = "\033[32m"
  RED = "\033[31m"
  RESET = "\033[0m"

  for line_num, effective_type, display_directive, pattern_str, regex in directives:
    matching_symbols = [s for s in symbols if regex.search(s)]

    eval_str = display_directive
    if display_directive != effective_type:
      eval_str = f"{display_directive} (evaluating as {effective_type})"

    if effective_type == "HAS-SYMBOL":
      if matching_symbols:
        print(f"  {GREEN}[PASS]{RESET} Line {line_num}: {eval_str}: {pattern_str}")
      else:
        print(f"  {RED}[FAIL]{RESET} Line {line_num}: {eval_str}: {pattern_str} (expected symbol not found)")
        failed = True
    elif effective_type == "HAS-SYMBOL-NOT":
      if not matching_symbols:
        print(f"  {GREEN}[PASS]{RESET} Line {line_num}: {eval_str}: {pattern_str}")
      else:
        print(f"  {RED}[FAIL]{RESET} Line {line_num}: {eval_str}: {pattern_str} (unwanted symbol found: '{matching_symbols[0].strip()}')")
        failed = True

  if failed:
    with tempfile.NamedTemporaryFile(mode="w", delete=False, prefix="demangled_symbols_", suffix=".txt") as tmp_file:
      for sym in symbols:
        tmp_file.write(sym + "\n")
      tmp_path = tmp_file.name
    print(f"Demangled symbols written to: {tmp_path}")
    print("❌ Symbol verification failed!")
    sys.exit(1)

  print("✅ Symbol verification passed!")


if __name__ == "__main__":
  main()
