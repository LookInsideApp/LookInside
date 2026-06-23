require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinServerInjected'
  LookinPodspecHelpers.apply_common_metadata(s, 'Constructor-based LookInside server bootstrap for injected builds.')

  s.module_name = 'LookinServerInjected'
  s.static_framework = false
  s.dependency 'LookinServerDynamic'

  s.source_files = 'Sources/LookinServerInjected/**/*.{h,m}'

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => LookinPodspecHelpers.base_defines
  }
end
