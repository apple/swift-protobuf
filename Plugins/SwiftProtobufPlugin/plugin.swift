import Foundation
import PackagePlugin

@main
struct SwiftProtobufPlugin {
    /// Errors thrown by the `SwiftProtobufPlugin`
    enum PluginError: Error, CustomStringConvertible {
        /// Indicates that the target where the plugin was applied to was not `SourceModuleTarget`.
        case invalidTarget(Target)
        /// Indicates that the file extension of an input file was not `.proto`.
        case invalidInputFileExtension(String)
        /// Indicates that there was no configuration file at the required location.
        case noConfigFound(String)

        var description: String {
            switch self {
            case let .invalidTarget(target):
                return "Expected a SwiftSourceModuleTarget but got '\(type(of: target))'."
            case let .invalidInputFileExtension(path):
                return "The input file '\(path)' does not have a '.proto' extension."
            case let .noConfigFound(path):
                return """
                    No configuration file found named '\(path)'. The file must not be listed in the \
                    'exclude:' argument for the target in Package.swift.
                    """
            }
        }
    }

    /// The configuration of the plugin.
    struct Configuration: Codable {
        /// Encapsulates a single invocation of protoc.
        struct Invocation: Codable {
            /// The visibility of the generated files.
            enum Visibility: String, Codable {
                /// The generated files should have `internal` access level.
                case `internal` = "Internal"
                /// The generated files should have `public` access level.
                case `public` = "Public"
                /// The generated files should have `package` access level.
                /// - Note: Swift 5.9 or later is needed to use this option.
                case `package` = "Package"

                init?(rawValue: String) {
                    switch rawValue.lowercased() {
                    case "internal":
                        self = .internal
                    case "public":
                        self = .public
                    case "package":
                        self = .package
                    default:
                        return nil
                    }
                }
            }

            enum FileNaming: String, Codable {
                /// The generated Swift file paths will be using the same relative path as the input proto files.
                case fullPath = "FullPath"
                /// The generated Swift file paths will the the relative paths but each directory replaced with an `_`.
                case pathToUnderscores = "PathToUnderscores"
                /// The generated Swift files will just be using the file name and drop the rest of the relative path.
                case dropPath = "DropPath"

                init?(rawValue: String) {
                    switch rawValue.lowercased() {
                    case "fullpath", "full_path":
                        self = .fullPath
                    case "pathtounderscores", "path_to_underscores":
                        self = .pathToUnderscores
                    case "droppath", "drop_path":
                        self = .dropPath
                    default:
                        return nil
                    }
                }
            }

            /// An array of paths to `.proto` files for this invocation.
            var protoFiles: [String]
            /// The visibility of the generated files.
            var visibility: Visibility?
            /// The file naming strategy to use.
            var fileNaming: FileNaming?
            /// Whether internal imports should be annotated as `@_implementationOnly`.
            var implementationOnlyImports: Bool?
        }

        /// The path to the `protoc` binary.
        ///
        /// If this is not set, SPM will try to find the tool itself.
        var protocPath: String?

        /// A list of invocations of `protoc` with the `SwiftProtobuf` plugin.
        var invocations: [Invocation]
    }

    static let configurationFileName = "swift-protobuf-config.json"

    /// Create build commands for the given arguments
    /// - Parameters:
    ///   - pluginWorkDirectory: The path of a writable directory into which the plugin or the build
    ///   commands it constructs can write anything it wants.
    ///   - sourceFiles: The input files that are associated with the target.
    ///   - tool: The tool method from the context.
    /// - Returns: The build commands configured based on the arguments.
    func createBuildCommands(
        pluginWorkDirectory: PackagePlugin.Path,
        sourceFiles: FileList,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool
    ) throws -> [Command] {
        guard let configurationFilePath = sourceFiles.first(
            where: {
                $0.path.lastComponent == Self.configurationFileName
            }
        )?.path else {
            throw PluginError.noConfigFound(Self.configurationFileName)
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: "\(configurationFilePath)"))
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)
        try validateConfiguration(configuration)

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
            protocPath = try tool("protoc").path
        }
        let protocGenSwiftPath = try tool("protoc-gen-swift").path

        return configuration.invocations.map { invocation in
            self.invokeProtoc(
                directory: configurationFilePath.removingLastComponent(),
                invocation: invocation,
                protocPath: protocPath,
                protocGenSwiftPath: protocGenSwiftPath,
                outputDirectory: pluginWorkDirectory
            )
        }
    }

    /// Invokes `protoc` with the given inputs
    ///
    /// - Parameters:
    ///   - directory: The plugin's target directory.
    ///   - invocation: The `protoc` invocation.
    ///   - protocPath: The path to the `protoc` binary.
    ///   - protocGenSwiftPath: The path to the `protoc-gen-swift` binary.
    ///   - outputDirectory: The output directory for the generated files.
    /// - Returns: The build command configured based on the arguments.
    private func invokeProtoc(
        directory: PackagePlugin.Path,
        invocation: Configuration.Invocation,
        protocPath: Path,
        protocGenSwiftPath: Path,
        outputDirectory: Path
    ) -> Command {
        // Construct the `protoc` arguments.
        var protocArgs = [
            "--plugin=protoc-gen-swift=\(protocGenSwiftPath)",
            "--swift_out=\(outputDirectory)",
        ]

        // We need to add the target directory as a search path since we require the user to specify
        // the proto files relative to it.
        protocArgs.append("-I")
        protocArgs.append("\(directory)")

        // Add the visibility if it was set
        if let visibility = invocation.visibility {
            protocArgs.append("--swift_opt=Visibility=\(visibility.rawValue)")
        }

        // Add the file naming if it was set
        if let fileNaming = invocation.fileNaming {
            protocArgs.append("--swift_opt=FileNaming=\(fileNaming.rawValue)")
        }

        // Add the implementation only imports flag if it was set
        if let implementationOnlyImports = invocation.implementationOnlyImports {
            protocArgs.append("--swift_opt=ImplementationOnlyImports=\(implementationOnlyImports)")
        }

        var inputFiles = [Path]()
        var outputFiles = [Path]()

        for var file in invocation.protoFiles {
            // Append the file to the protoc args so that it is used for generating
            protocArgs.append("\(file)")
            inputFiles.append(directory.appending(file))

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
                    throw PluginError.invalidInputFileExtension(protoFile)
                }
            }
        }
    }
}

extension SwiftProtobufPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            throw PluginError.invalidTarget(target)
        }
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            sourceFiles: swiftTarget.sourceFiles,
            tool: context.tool
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftProtobufPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            sourceFiles: target.inputFiles,
            tool: context.tool
        )
    }
}
#endif
