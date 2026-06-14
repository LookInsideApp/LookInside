require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinServer'
  LookinPodspecHelpers.apply_common_metadata(s, 'LookInside debug server for iOS applications.')

  s.module_name = 'LookinServer'
  s.requires_arc = true
  s.static_framework = true
  s.default_subspec = 'Server'

  s.subspec 'Base' do |ss|
    ss.source_files = 'Sources/LookinServerBase/**/*.{h,m}'
    ss.public_header_files = 'Sources/LookinServerBase/**/*.h'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => LookinPodspecHelpers.base_defines,
      'HEADER_SEARCH_PATHS' => LookinPodspecHelpers.header_search_paths('Sources/LookinServerBase')
    }
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'LookinServer/Base'
    ss.source_files = [
      'Sources/LookinCore/**/*.{h,m}',
      'Sources/LookinServer/Server/Category/UIColor+LookinServer.h',
      'Sources/LookinServer/Server/Category/UIImage+LookinServer.h'
    ]
    ss.exclude_files = 'Sources/LookinCore/include/LookinCore.h'
    ss.public_header_files = 'Sources/LookinCore/**/*.h'
    ss.private_header_files = [
      'Sources/LookinServer/Server/Category/UIColor+LookinServer.h',
      'Sources/LookinServer/Server/Category/UIImage+LookinServer.h'
    ]
    ss.pod_target_xcconfig = {
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

  s.subspec 'Shared' do |ss|
    ss.dependency 'LookinServer/Core'
    ss.dependency 'LookinServer/Base'
  end

  s.subspec 'Server' do |ss|
    ss.dependency 'LookinServer/Shared'
    ss.source_files = [
      'Sources/LookinServer/Server/**/*.{h,m}'
    ]
    ss.public_header_files = [
      'Sources/LookinServer/Server/LookinServer.h',
      'Sources/LookinServer/include/LookinServer.h',
      'Sources/LookinServer/Server/**/*.h'
    ]
    ss.tvos.exclude_files = [
      'Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.{h,m}'
    ]
    ss.pod_target_xcconfig = {
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
end
