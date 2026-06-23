require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinCore'
  LookinPodspecHelpers.apply_common_metadata(s, 'Shared LookInside data models and utilities.')

  s.module_name = 'LookinCore'
  s.static_framework = true
  s.dependency 'LookinServerBase'

  s.source_files = [
    'Sources/LookinCore/**/*.{h,m}',
    'Sources/LookinServer/Server/Category/UIColor+LookinServer.h',
    'Sources/LookinServer/Server/Category/UIImage+LookinServer.h'
  ]
  s.exclude_files = 'Sources/LookinCore/include/LookinCore.h'
  s.public_header_files = 'Sources/LookinCore/**/*.h'
  s.private_header_files = [
    'Sources/LookinServer/Server/Category/UIColor+LookinServer.h',
    'Sources/LookinServer/Server/Category/UIImage+LookinServer.h'
  ]

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => LookinPodspecHelpers.base_defines,
    'HEADER_SEARCH_PATHS' => LookinPodspecHelpers.header_search_paths(
      'Sources/LookinCore',
      'Sources/LookinCore/include',
      'Sources/LookinCore/Category',
      'Sources/LookinCore/Peertalk',
      'Sources/LookinServer/Server/Category'
    )
  }
end
