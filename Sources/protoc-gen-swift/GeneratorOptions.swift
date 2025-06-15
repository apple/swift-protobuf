// Sources/protoc-gen-swift/GeneratorOptions.swift - Wrapper for generator options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

package class GeneratorOptions {
    enum OutputNaming {
        case fullPath
        case pathToUnderscores
        case dropPath

        init?(flag: String) {
            switch flag.lowercased() {
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

    package enum Visibility: String {
        case `internal`
        case `public`
        case `package`

        init?(flag: String) {
            self.init(rawValue: flag.lowercased())
        }
    }

    package enum ImportDirective: Equatable {
        case accessLevel(Visibility)
        case plain
        case implementationOnly

        var isAccessLevel: Bool {
            switch self {
            case .accessLevel: return true
            default: return false
            }
        }

        var snippet: String {
            switch self {
            case let .accessLevel(visibility):
                return "\(visibility.rawValue) import"
            case .plain:
                return "import"
            case .implementationOnly:
                return "@_implementationOnly import"
            }
        }
    }
    
    package enum ExtensionType {
        case equatable
        case hashable
        case nameProviding
        
        init?(flag: String) {
            switch flag.lowercased() {
            case "equatable":
                self = .equatable
            case "hashable":
                self = .hashable
            case "nameproviding", "name_providing":
                self = .nameProviding
            default:
                return nil
            }
        }
    }
    
    package enum ExtensionOutputConfiguration {
        case normal
        case debugOnly
        case skip
        
        init?(flag: String) {
            switch flag.lowercased() {
            case "normal":
                self = .normal
            case "debugonly", "debug_only":
                self = .debugOnly
            case "skip":
                self = .skip
            default:
                return nil
            }
        }
    }
    
    package struct ExtensionOutputConfigurationStorage {
        var defaultValue: ExtensionOutputConfiguration
        var typeSpecificValue: [String: ExtensionOutputConfiguration]
    }

    let outputNaming: OutputNaming
    let protoToModuleMappings: ProtoFileToModuleMappings
    let visibility: Visibility
    let importDirective: ImportDirective
    let experimentalStripNonfunctionalCodegen: Bool
    let equatableOutputConfiguration: ExtensionOutputConfigurationStorage
    let hashableOutputConfiguration: ExtensionOutputConfigurationStorage
    let nameProvidingOutputConfiguration: ExtensionOutputConfigurationStorage

    /// A string snippet to insert for the visibility
    let visibilitySourceSnippet: String

    init(parameter: any CodeGeneratorParameter) throws {
        var outputNaming: OutputNaming = .fullPath
        var moduleMapPath: String?
        var visibility: Visibility = .internal
        var swiftProtobufModuleName: String? = nil
        var implementationOnlyImports: Bool = false
        var useAccessLevelOnImports = false
        var experimentalStripNonfunctionalCodegen: Bool = false
        var equatableOutputConfiguration = ExtensionOutputConfigurationStorage(
            defaultValue: .normal,
            typeSpecificValue: [:]
        )
        var hashableOutputConfiguration = ExtensionOutputConfigurationStorage(
            defaultValue: .normal,
            typeSpecificValue: [:]
        )
        var nameProvidingOutputConfiguration = ExtensionOutputConfigurationStorage(
            defaultValue: .normal,
            typeSpecificValue: [:]
        )

        for pair in parameter.parsedPairs {
            switch pair.key {
            case "FileNaming":
                if let naming = OutputNaming(flag: pair.value) {
                    outputNaming = naming
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "ProtoPathModuleMappings":
                if !pair.value.isEmpty {
                    moduleMapPath = pair.value
                }
            case "Visibility":
                if let value = Visibility(flag: pair.value) {
                    visibility = value
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "SwiftProtobufModuleName":
                // This option is not documented in PLUGIN.md, because it's a feature
                // that would ordinarily not be required for a given adopter.
                if isValidSwiftIdentifier(pair.value) {
                    swiftProtobufModuleName = pair.value
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "ImplementationOnlyImports":
                if let value = Bool(pair.value) {
                    implementationOnlyImports = value
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "UseAccessLevelOnImports":
                if let value = Bool(pair.value) {
                    useAccessLevelOnImports = value
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "experimental_strip_nonfunctional_codegen":
                if pair.value.isEmpty {  // Also support option without any value.
                    experimentalStripNonfunctionalCodegen = true
                } else if let value = Bool(pair.value) {
                    experimentalStripNonfunctionalCodegen = value
                } else {
                    throw GenerationError.invalidParameterValue(
                        name: pair.key,
                        value: pair.value
                    )
                }
            case "GenerateExtensions":
                for config in pair.value.split(separator: ";") {
                    let configPair = config.split(separator: "=")
                    if configPair.count == 2 {
                        let extensionType: ExtensionType?
                        var typeName: String?
                        
                        let configKey = configPair[0].split(separator: ":")
                        if configKey.count == 1 {
                            extensionType = ExtensionType(flag: String(configKey[0]))
                        } else if configKey.count == 2 {
                            typeName = String(configKey[0])
                            extensionType = ExtensionType(flag: String(configKey[1]))
                        } else {
                            continue
                        }
                        
                        let outputValue = ExtensionOutputConfiguration(flag: String(configPair[1]))
                        
                        guard
                            let extensionType = extensionType,
                            let outputValue = outputValue
                        else {
                            continue
                        }
                        
                        if let typeName = typeName {
                            switch extensionType {
                            case .equatable:
                                equatableOutputConfiguration.typeSpecificValue[typeName] = outputValue
                            case .hashable:
                                hashableOutputConfiguration.typeSpecificValue[typeName] = outputValue
                            case .nameProviding:
                                nameProvidingOutputConfiguration.typeSpecificValue[typeName] = outputValue
                            }
                        } else {
                            switch extensionType {
                            case .equatable:
                                equatableOutputConfiguration.defaultValue = outputValue
                            case .hashable:
                                hashableOutputConfiguration.defaultValue = outputValue
                            case .nameProviding:
                                nameProvidingOutputConfiguration.defaultValue = outputValue
                            }
                        }
                    }
                }
                break
            default:
                throw GenerationError.unknownParameter(name: pair.key)
            }
        }

        if let moduleMapPath = moduleMapPath {
            do {
                self.protoToModuleMappings = try ProtoFileToModuleMappings(
                    path: moduleMapPath,
                    swiftProtobufModuleName: swiftProtobufModuleName
                )
            } catch let e {
                throw GenerationError.wrappedError(
                    message: "Parameter 'ProtoPathModuleMappings=\(moduleMapPath)'",
                    error: e
                )
            }
        } else {
            self.protoToModuleMappings = ProtoFileToModuleMappings(swiftProtobufModuleName: swiftProtobufModuleName)
        }

        self.outputNaming = outputNaming
        self.visibility = visibility

        switch visibility {
        case .internal:
            visibilitySourceSnippet = ""
        case .public:
            visibilitySourceSnippet = "public "
        case .package:
            visibilitySourceSnippet = "package "
        }

        self.experimentalStripNonfunctionalCodegen = experimentalStripNonfunctionalCodegen

        switch (implementationOnlyImports, useAccessLevelOnImports) {
        case (false, false): self.importDirective = .plain
        case (false, true): self.importDirective = .accessLevel(visibility)
        case (true, false): self.importDirective = .implementationOnly
        case (true, true):
            throw GenerationError.message(
                message: """
                    When using access levels on imports the @_implementationOnly option is unnecessary.
                    Disable @_implementationOnly imports.
                    """
            )
        }

        // ------------------------------------------------------------------------
        // Now do "cross option" validations.

        if implementationOnlyImports && self.visibility != .internal {
            throw GenerationError.message(
                message: """
                    Cannot use @_implementationOnly imports when the proto visibility is public or package.
                    Either change the visibility to internal, or disable @_implementationOnly imports.
                    """
            )
        }

        // The majority case is that if `self.protoToModuleMappings.hasMappings` is
        // true, then `self.visibility` should be either `.public` or `.package`.
        // However, it is possible for someone to put top most proto files (ones
        // not imported into other proto files) in a different module, and use
        // internal visibility there. i.e. -
        //
        //    module One:
        //    - foo.pb.swift from foo.proto generated with "public" visibility.
        //    module Two:
        //    - bar.pb.swift from bar.proto (which does `import foo.proto`)
        //      generated with "internal" visibility.
        //
        // Since this support is possible/valid, there's no good way a "bad" case
        // (i.e. - if foo.pb.swift was generated with "internal" visibility). So
        // no options validation here, and instead developers would have to figure
        // this out via the compiler errors around missing type (when bar.pb.swift
        // gets unknown reference for thing that should be in module One via
        // foo.pb.swift).
        
        self.equatableOutputConfiguration = equatableOutputConfiguration
        self.hashableOutputConfiguration = hashableOutputConfiguration
        self.nameProvidingOutputConfiguration = nameProvidingOutputConfiguration
    }
}

extension GeneratorOptions.ExtensionOutputConfigurationStorage {
    func configuration(for typeName: String) -> GeneratorOptions.ExtensionOutputConfiguration {
        return typeSpecificValue[typeName] ?? defaultValue
    }
}

extension GeneratorOptions.ExtensionOutputConfiguration {
    func generateExtension(
        printer p: inout CodePrinter,
        typeFullName: String,
        extensionFullName: String,
        extensionBody: ((_ p: inout CodePrinter) -> Void)?
    ) {
        switch self {
        case .normal:
            p.print(
                "",
                "extension \(typeFullName): \(extensionFullName) {"
            )
            p.withIndentation { p in
                extensionBody?(&p)
            }
            p.print("}")
        case .debugOnly:
            p.print(
                "",
                "#if DEBUG",
                "extension \(typeFullName): \(extensionFullName) {"
            )            
            p.withIndentation { p in
                extensionBody?(&p)
            }
            p.print(
                "}",
                "#endif"
            )
        case .skip:
            return
        }
    }
}
