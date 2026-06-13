module LookinPodspecHelpers
  VERSION = '0.1.0'
  HOMEPAGE = 'https://lookinside-app.com'
  AUTHOR = { 'LookInside' => 'support@lookinside-app.com' }.freeze

  module_function

  def apply_common_metadata(spec, summary)
    spec.version = VERSION
    spec.summary = summary
    spec.description = summary
    spec.homepage = HOMEPAGE
    spec.license = { :type => 'MIT', :file => 'LICENSE' }
    spec.author = AUTHOR
    spec.source = { :path => '.' }
    spec.ios.deployment_target = '12.0'
    spec.tvos.deployment_target = '12.0'
    spec.osx.deployment_target = '11.0'
    spec.requires_arc = true
  end

  def base_defines
    '$(inherited) SHOULD_COMPILE_LOOKIN_SERVER=1'
  end

  def header_search_paths(*paths)
    paths.flatten.map { |path| %("$(PODS_TARGET_SRCROOT)/#{path}") }.unshift('$(inherited)').join(' ')
  end
end
