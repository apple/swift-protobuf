Pod::Spec.new do |s|
  s.name = 'SwiftProtobufFoundationCompat'
  s.version = '2.0.0'
  s.license = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.summary = 'Swift Protobuf Foundation Compatibility Library'
  s.homepage = 'https://github.com/apple/swift-protobuf'
  s.author = 'Apple Inc.'
  s.source = { :git => 'https://github.com/apple/swift-protobuf.git', :tag => s.version }

  s.requires_arc = true
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.cocoapods_version = '>= 1.7.0'

  s.source_files = 'Sources/SwiftProtobufFoundationCompat/**/*.swift'

  # Require and exact match on the dependency, since it isn't yet clear
  # if we'll be able to support interop between minor/bugfixes.
  s.dependency 'SwiftProtobufCore', "= #{s.version}"

  s.swift_versions = ['5.0']
end
