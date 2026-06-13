require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinServer'
  LookinPodspecHelpers.apply_common_metadata(s, 'LookInside debug server for iOS applications.')

  s.module_name = 'LookinServer'
  s.requires_arc = true
  s.static_framework = true
  s.dependency 'LookinShared'

  s.source_files = [
    'Sources/LookinServer/Server/**/*.{h,m}'
  ]

  s.public_header_files = [
    'Sources/LookinServer/Server/LookinServer.h',
    'Sources/LookinServer/include/LookinServer.h',
    'Sources/LookinServer/Server/**/*.h'
  ]

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => LookinPodspecHelpers.base_defines,
    'HEADER_SEARCH_PATHS' => LookinPodspecHelpers.header_search_paths(
      'Sources/LookinServer/Server',
      'Sources/LookinServer/Server/Category',
      'Sources/LookinServer/Server/Connection',
      'Sources/LookinServer/Server/Connection/RequestHandler',
      'Sources/LookinServer/Server/Others'
    )
  }
end
