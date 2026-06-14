require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinServerDynamic'
  LookinPodspecHelpers.apply_common_metadata(s, 'Dynamic-framework CocoaPods package for LookInside debug server.')

  s.module_name = 'LookinServer'
  s.static_framework = false
  s.dependency 'LookinServer/Shared'

  s.source_files = [
    'Sources/LookinServer/Server/**/*.{h,m}'
  ]

  s.public_header_files = [
    'Sources/LookinServer/Server/LookinServer.h',
    'Sources/LookinServer/include/LookinServer.h',
    'Sources/LookinServer/Server/**/*.h'
  ]
  s.tvos.exclude_files = [
    'Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.{h,m}'
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
