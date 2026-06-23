require_relative 'LookinPodspecHelpers'

Pod::Spec.new do |s|
  s.name = 'LookinShared'
  LookinPodspecHelpers.apply_common_metadata(s, 'Aggregate CocoaPods dependency for LookInside shared libraries.')

  s.module_name = 'LookinShared'
  s.static_framework = true
  s.dependency 'LookinCore'
  s.dependency 'LookinServerBase'
end
