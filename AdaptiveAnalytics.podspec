Pod::Spec.new do |s|

  s.name             = 'AdaptiveAnalytics'
  s.version          = '1.0.32'
  s.summary          = 'Analytics module for AdaptiveSDK — learning event tracking.'

  s.homepage         = 'https://github.com/AdaptiveSDK/AdaptiveiOSSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AlAdwaa' => 'dev_team@aladwaa.org' }
  s.source           = { :git => 'https://github.com/AdaptiveSDK/AdaptiveiOSSDK.git', :tag => s.version.to_s }

  s.swift_version          = '5.9'
  s.ios.deployment_target  = '13.0'

  s.source_files = 'Sources/AdaptiveSDK/AdaptiveAnalytics/Sources/AdaptiveAnalytics/**/*.swift'
  s.dependency     'AdaptiveCore', '~> 1.0'

end
