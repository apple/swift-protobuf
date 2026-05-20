# CompileTests/ExperimentalHiddenNames

This is a test case that uses the experimental feature to not generate some of the
metadata that would be used for TextFormat/JSON. It ensures apis still "work" as
expected with this option enabled.

This can't use the SwiftPM Plugin as that currently doesn't have support for the
the generation option.
