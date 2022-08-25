import Foundation
import PackagePlugin

@main
struct SwiftProtobufPlugin: BuildToolPlugin {
    /// Errors thrown by the `SwiftProtobufPlugin`
    enum PluginError: Error {
        /// Indicates that the target where the plugin was applied to was not `SourceModuleTarget`.
        case invalidTarget
        /// Indicates that the file extension of an input file was not `.proto`.
        case invalidInputFileExtension
    }

    /// The configuration of the plugin.
    struct Configuration: Codable {
        /// Encapsulates a single invocation of protoc.
        struct Invocation: Codable {
            /// The visibility of the generated files.
            enum Visibility: String, Codable {
                /// The generated files should have `internal` access level.
                case `internal`
                /// The generated files should have `public` access level.
                case `public`
            }

            /// An array of paths to `.proto` files for this invocation.
            var protoFiles: [String]
            /// The visibility of the generated files.
            var visibility: Visibility?
        }

        /// The path to the `protoc` binary.
        ///
        /// If this is not set, SPM will try to find the tool itself.
        var protocPath: String?

        /// A list of invocations of `protoc` with the `SwiftProtobuf` plugin.
        var invocations: [Invocation]
    }

    static let configurationFileName = "swift-protobuf-config.json"

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // Let's check that this is a source target
        guard let target = target as? SourceModuleTarget else {
            throw PluginError.invalidTarget
        }

        // We need to find the configuration file at the root of the target
        let configurationFilePath = target.directory.appending(subpath: Self.configurationFileName)
        let data = try Data(contentsOf: URL(fileURLWithPath: "\(configurationFilePath)"))
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)

        try self.validateConfiguration(configuration)

        // We need to find the path of protoc and protoc-gen-swift
        let protocPath: Path
        if let configuredProtocPath = configuration.protocPath {
            // The user set the config path in the file. So let's take that
            protocPath = Path(configuredProtocPath)
        } else if let environmentPath = ProcessInfo.processInfo.environment["PROTOC_PATH"] {
            // The user set the env variable. So let's take that
            protocPath = Path(environmentPath)
        } else {
            // The user didn't set anything so let's try see if SPM can find a binary for us
            protocPath = try context.tool(named: "protoc").path
        }
        let protocGenSwiftPath = try context.tool(named: "protoc-gen-swift").path

        // This plugin generates its output into GeneratedSources
        let outputDirectory = context.pluginWorkDirectory

        return configuration.invocations.map { invocation in
            self.invokeProtoc(
                target: target,
                invocation: invocation,
                protocPath: protocPath,
                protocGenSwiftPath: protocGenSwiftPath,
                outputDirectory: outputDirectory
            )
        }
    }

    /// Invokes `protoc` with the given inputs
    ///
    /// - Parameters:
    ///   - target: The plugin's target.
    ///   - invocation: The `protoc` invocation.
    ///   - protocPath: The path to the `protoc` binary.
    ///   - protocGenSwiftPath: The path to the `protoc-gen-swift` binary.
    ///   - outputDirectory: The output directory for the generated files.
    /// - Returns: The build command.
    private func invokeProtoc(
        target: Target,
        invocation: Configuration.Invocation,
        protocPath: Path,
        protocGenSwiftPath: Path,
        outputDirectory: Path
    ) -> Command {
        // Construct the `protoc` arguments.
        var protocArgs = [
            "--plugin=protoc-gen-swift=\(protocGenSwiftPath)",
            "--swift_out=\(outputDirectory)",
            // We include the target directory as a proto search path
            "-I",
            "\(target.directory)",
        ]

        // Add the visibility if it was set
        if let visibility = invocation.visibility {
            protocArgs.append("--swift_opt=Visibility=\(visibility.rawValue.capitalized)")
        }

        var inputFiles = [Path]()
        var outputFiles = [Path]()

        for var file in invocation.protoFiles {
            // Append the file to the protoc args so that it is used for generating
            protocArgs.append("\(file)")
            inputFiles.append(target.directory.appending(file))

            // The name of the output file is based on the name of the input file.
            // We validated in the beginning that every file has the suffix of .proto
            // This means we can just drop the last 5 elements and append the new suffix
            file.removeLast(5)
            file.append("pb.swift")
            let protobufOutputPath = outputDirectory.appending(file)

            // Add the outputPath as an output file
            outputFiles.append(protobufOutputPath)
        }

        // Construct the command. Specifying the input and output paths lets the build
        // system know when to invoke the command. The output paths are passed on to
        // the rule engine in the build system.
        return Command.buildCommand(
            displayName: "Generating swift files from proto files",
            executable: protocPath,
            arguments: protocArgs,
            inputFiles: inputFiles + [protocGenSwiftPath],
            outputFiles: outputFiles
        )
    }

    /// Validates the configuration file for various user errors.
    private func validateConfiguration(_ configuration: Configuration) throws {
        for invocation in configuration.invocations {
            for protoFile in invocation.protoFiles {
                if !protoFile.hasSuffix(".proto") {
                    throw PluginError.invalidInputFileExtension
                }
            }
        }
    }
}
