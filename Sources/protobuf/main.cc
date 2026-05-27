#include <cstring>
#include <string>
#include <vector>

#include "google/protobuf/compiler/command_line_interface.h"
#include "absl/log/initialize.h"

namespace {
std::string WellKnownTypesIncludeFlag() {
  // __FILE__ is .../Sources/protobuf/main.cc, the WKT protos are siblings
  // to main.cc in .../Sources/protobuf/include.
  std::string file = __FILE__;
  auto slash = file.find_last_of("/\\");
  std::string dir = (slash == std::string::npos) ? std::string(".")
                                                 : file.substr(0, slash);
  return "-I" + dir + "/include";
}

// Matches "-I" / "-I<value>" / "--proto_path" / "--proto_path=<value>".
//
// See also CommandLineInterface::ParseArgument()
bool IsProtoPathFlag(const char* arg) {
  return std::strcmp(arg, "-I") == 0 ||
         (std::strncmp(arg, "-I", 2) == 0 && arg[2] != '\0') ||
         std::strcmp(arg, "--proto_path") == 0 ||
         std::strncmp(arg, "--proto_path=", 13) == 0;
}

// Matches "--descriptor_set_in" / "--descriptor_set_in=<value>".
//
// See also CommandLineInterface::ParseArgument()
bool IsDescriptorSetInFlag(const char* arg) {
  return std::strcmp(arg, "--descriptor_set_in") == 0 ||
         std::strncmp(arg, "--descriptor_set_in=", 20) == 0;
}
}  // namespace

// Follows the shape of the upstream entrypoint (main_no_generators.cc) but
// injects an additional "-I" for the WKTs.
int main(int argc, char* argv[]) {
  absl::InitializeLog();

  // CommandLineInterface::Run() calls ParseArguments() to collect every
  // -I/--proto_path into proto_path_, then InitializeDiskSourceTree()
  // registers those entries in the order they were parsed. Appending the
  // WKT include to argv places it last in proto_path_, so caller-supplied
  // -I entries take precedence (this avoids protoc's "input is shadowed" check
  // when the caller's tree also carries google/protobuf/*.proto copies).
  //
  // Run() also gates disk access on proto_path_ being non-empty. After
  // ParseArguments() the only mode that leaves proto_path_ empty, and
  // therefore skips disk initialization, is "--descriptor_set_in with no
  // -I". Adding -I in would force disk initialization and change the behavior
  // of Run().
  bool has_proto_path = false;
  bool has_descriptor_set_in = false;

  std::string wkt_flag;
  std::vector<char*> new_argv;
  new_argv.reserve(argc + 3);
  for (int i = 0; i < argc; ++i) {
    if (IsProtoPathFlag(argv[i])) {
      has_proto_path = true;
    }
    if (IsDescriptorSetInFlag(argv[i])) {
      has_descriptor_set_in = true;
    }

    new_argv.push_back(argv[i]);
  }

  if (has_proto_path || !has_descriptor_set_in) {
    if (!has_proto_path && !has_descriptor_set_in) {
      // protoc implicitly uses "." if neither is set. This would be skipped
      // by inserting "-I" for the WKTs so explicitly add it back.
      new_argv.push_back(const_cast<char*>("-I."));
    }
    wkt_flag = WellKnownTypesIncludeFlag();
    new_argv.push_back(const_cast<char*>(wkt_flag.c_str()));
  }

  google::protobuf::compiler::CommandLineInterface cli;
  cli.AllowPlugins("protoc-");

  return cli.Run(static_cast<int>(new_argv.size()), new_argv.data());
}
