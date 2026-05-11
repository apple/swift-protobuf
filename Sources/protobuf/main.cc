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
}  // namespace

int main(int argc, char* argv[]) {
  absl::InitializeLog();

  const std::string wkt_flag = WellKnownTypesIncludeFlag();

  std::vector<char*> new_argv;
  new_argv.reserve(argc + 1);
  new_argv.push_back(argv[0]);
  new_argv.push_back(const_cast<char*>(wkt_flag.c_str()));
  for (int i = 1; i < argc; ++i) {
    new_argv.push_back(argv[i]);
  }

  google::protobuf::compiler::CommandLineInterface cli;
  cli.AllowPlugins("protoc-");

  return cli.Run(static_cast<int>(new_argv.size()), new_argv.data());
}
