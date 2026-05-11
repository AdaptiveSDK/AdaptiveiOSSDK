Pod::Spec.new do |s|

  s.name             = 'AdaptiveCore'
  s.version          = '1.0.28'
  s.summary          = 'Core module for AdaptiveSDK — initialization, user session, networking & offline queue.'

  s.homepage         = 'https://github.com/AdaptiveSDK/AdaptiveiOSSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AlAdwaa' => 'dev_team@aladwaa.org' }
  s.source           = { :git => 'https://github.com/AdaptiveSDK/AdaptiveiOSSDK.git', :tag => s.version.to_s }

  s.swift_version          = '5.9'
  s.ios.deployment_target  = '13.0'

  s.source_files = 'Sources/AdaptiveSDK/AdaptiveCore/Sources/AdaptiveCore/**/*.swift'
  s.frameworks   = 'Foundation', 'Network', 'Combine'

end
