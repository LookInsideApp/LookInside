require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinServerBase'
  LookinPodspecHelpers.apply_common_metadata(s, 'Base model support for LookInside server libraries.')

  s.module_name = 'LookinServerBase'
  s.static_framework = true

  s.source_files = 'Sources/LookinServerBase/**/*.{h,m}'
  s.public_header_files = 'Sources/LookinServerBase/**/*.h'

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => LookinPodspecHelpers.base_defines,
    'HEADER_SEARCH_PATHS' => LookinPodspecHelpers.header_search_paths('Sources/LookinServerBase')
  }
end
