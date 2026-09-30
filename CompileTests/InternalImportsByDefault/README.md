# CompileTests/InternalImportsByDefault

This is a test case that ensures that generated code builds correctly when 
`InternalImportsByDefault` is enabled and the code is generated with public
visibility.

When support for access level modifiers on imports was first added, an issue 
was encountered where publicly-generated protos would generate build errors and 
warnings when `InternalImportsByDefault` was enabled, as some dependencies were 
imported without an explicit access level modifier (for example, `Foundation`), and some
where sometimes imported as `public` without actually being used in the 
generated code at all (for example, `Foundation` and `SwiftProtobuf`).
