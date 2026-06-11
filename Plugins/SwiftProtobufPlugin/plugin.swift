import Foundation
import PackagePlugin

@main
struct SwiftProtobufPlugin {
    /// Errors thrown by the `SwiftProtobufPlugin`
    enum PluginError: Error, CustomStringConvertible {
        /// Indicates that the target where the plugin was applied to was not `SourceModuleTarget`.
        case invalidTarget(String)
        /// Indicates that the file extension of an input file was not `.proto`.
        case invalidInputFileExtension(String)
        /// Indicates that there was no configuration file at the required location.
        case noConfigFound(String)

        var description: String {
            switch self {
            case let .invalidTarget(target):
                return "Expected a SwiftSourceModuleTarget but got '\(target)'."
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

            enum EnumGeneration: String, Codable {
                /// No `@nonexhaustive` attribute is emitted (default).
                /// Open proto enums are annotated with `@nonexhaustive`.
                case none = "None"
                case nonexhaustive = "Nonexhaustive"
                /// Open proto enums are annotated with `@nonexhaustive(warn)`.
                case nonexhaustiveWarn = "NonexhaustiveWarn"

                init?(rawValue: String) {
                    switch rawValue.lowercased() {
                    case "none":
                        self = .none
                    case "nonexhaustive":
                        self = .nonexhaustive
                    case "nonexhaustivewarn":
                        self = .nonexhaustiveWarn
                    default:
                        return nil
                    }
                }
            }

            /// An array of paths to `.proto` files for this invocation.
            ///
            /// If the `protoPath` parameter is specified, the files must be specified
            /// relative to that directory. Otherwise, relative to the target source directory.
            var protoFiles: [String]
            /// The visibility of the generated files.
            var visibility: Visibility?
            /// The file naming strategy to use.
            ///
            /// The build plugin always generates files with `PathToUnderscores` naming. The
            /// generated files live in the build directory, so the file name on disk is never
            /// observed and there is no benefit to giving users a choice here. This field is kept
            /// for backwards compatibility: it may be omitted or set to `PathToUnderscores`. Any
            /// other value is rejected so an explicit setting is never silently ignored.
            var fileNaming: FileNaming?
            /// Whether internal imports should be annotated as `@_implementationOnly`.
            var implementationOnlyImports: Bool?
            /// Whether import statements should be preceded with visibility.
            var useAccessLevelOnImports: Bool?
            /// The enum generation strategy to use.
            var enumGeneration: EnumGeneration?
            /// Overrides the base directory used to find protobuf files.
            ///
            /// This must be specified as a path relative to the target source directory.
            /// For example, if you are storing the protofiles at `MyLibrary/Sources/MyLib/protos`,
            /// you should specify `protos` as the value for this parameter.
            ///
            /// If you have multiple subdirectories you wish to include,
            /// you should specify multiple `invocations` instead.
            var protoPath: String?
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
        pluginWorkDirectory: URL,
        sourceFiles: FileList,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool
    ) throws -> [Command] {
        guard
            let configurationFilePath = sourceFiles.first(
                where: {
                    $0.url.lastPathComponent == Self.configurationFileName
                }
            )?.url
        else {
            throw PluginError.noConfigFound(Self.configurationFileName)
        }
        let data = try Data(contentsOf: configurationFilePath)
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)
        try validateConfiguration(configuration)

        // We need to find the path of protoc and protoc-gen-swift
        let protocPath: URL
        if let configuredProtocPath = configuration.protocPath {
            // The user set the config path in the file. So let's take that
            protocPath = URL(fileURLWithPath: configuredProtocPath)
        } else if let environmentPath = ProcessInfo.processInfo.environment["PROTOC_PATH"] {
            // The user set the env variable. So let's take that
            protocPath = URL(fileURLWithPath: environmentPath)
        } else {
            // The user didn't set anything so let's try see if SPM can find a binary for us
            protocPath = try tool("protoc").url
        }
        let protocGenSwiftPath = try tool("protoc-gen-swift").url

        return configuration.invocations.map { invocation in
            self.invokeProtoc(
                directory: configurationFilePath.deletingLastPathComponent(),
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
        directory: URL,
        invocation: Configuration.Invocation,
        protocPath: URL,
        protocGenSwiftPath: URL,
        outputDirectory: URL
    ) -> Command {
        // Construct the `protoc` arguments.
        var protocArgs = [
            "--plugin=protoc-gen-swift=\(protocGenSwiftPath.fileSystemPath)",
            "--swift_out=\(outputDirectory.fileSystemPath)",
        ]

        let protoDirectory =
            if let protoPath = invocation.protoPath {
                directory.appending(path: protoPath)
            } else {
                directory
            }

        protocArgs.append("-I")
        protocArgs.append(protoDirectory.fileSystemPath)

        // Add the visibility if it was set
        if let visibility = invocation.visibility {
            protocArgs.append("--swift_opt=Visibility=\(visibility.rawValue)")
        }

        // The build plugin always uses PathToUnderscores naming. Warn once per invocation on any
        // other explicit value so the setting is never silently ignored, without breaking existing
        // builds.
        if let fileNaming = invocation.fileNaming, fileNaming != .pathToUnderscores {
            Diagnostics.warning(
                """
                The 'fileNaming' option '\(fileNaming.rawValue)' is ignored by the build plugin. The build \
                plugin always generates files using the 'PathToUnderscores' naming because the \
                generated files go into the build directory and the name is never observed.
                """
            )
        }

        // Always generate with PathToUnderscores naming. The declared output paths below are
        // derived the same way, so the names the build system expects can never drift from the
        // names protoc-gen-swift actually writes. The configured fileNaming, if any, only triggers
        // the warning above and does not change the naming used.
        protocArgs.append("--swift_opt=FileNaming=PathToUnderscores")

        // Add the implementation only imports flag if it was set
        if let implementationOnlyImports = invocation.implementationOnlyImports {
            protocArgs.append("--swift_opt=ImplementationOnlyImports=\(implementationOnlyImports)")
        }

        // Add the useAccessLevelOnImports only imports flag if it was set
        if let useAccessLevelOnImports = invocation.useAccessLevelOnImports {
            protocArgs.append("--swift_opt=UseAccessLevelOnImports=\(useAccessLevelOnImports)")
        }

        // Add the enum generation strategy if it was set
        if let enumGeneration = invocation.enumGeneration {
            protocArgs.append("--swift_opt=EnumGeneration=\(enumGeneration.rawValue)")
        }
        var inputFiles = [URL]()
        var outputFiles = [URL]()

        for file in invocation.protoFiles {
            // Append the file to the protoc args so that it is used for generating
            protocArgs.append(file)
            inputFiles.append(protoDirectory.appending(path: file))

            // The output file name has to match exactly what protoc-gen-swift writes, otherwise
            // the build system looks for a file that does not exist and the build fails. We always
            // generate with PathToUnderscores naming, so the relative proto path becomes a single
            // file name with the directory separators replaced by underscores. We validated up
            // front that every file has the .proto suffix, which is dropped for .pb.swift.
            let outputName = String(file.dropLast(".proto".count))
                .replacingOccurrences(of: "/", with: "_") + ".pb.swift"
            let protobufOutputPath = outputDirectory.appending(path: outputName)

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
            throw PluginError.invalidTarget(String(describing: type(of: target)))
        }
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectoryURL,
            sourceFiles: swiftTarget.sourceFiles,
            tool: context.tool
        )
    }
}

extension URL {
    fileprivate var fileSystemPath: String {
        #if canImport(Darwin)
        return self.path(percentEncoded: false)
        #else
        return self.path()
        #endif
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftProtobufPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectoryURL,
            sourceFiles: target.inputFiles,
            tool: context.tool
        )
    }
}
#endif
