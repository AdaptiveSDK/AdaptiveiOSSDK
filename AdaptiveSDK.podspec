Pod::Spec.new do |s|

  s.name             = 'AdaptiveSDK'
  s.version          = '1.0.0'
  s.summary          = 'Modular Swift SDK for adaptive learning — analytics, messaging, and core networking.'
  s.description      = <<-DESC
    AdaptiveSDK is a meta-pod that pulls in all Adaptive modules:
    AdaptiveCore, AdaptiveAnalytics, and AdaptiveMessaging.
  DESC

  s.homepage         = 'https://github.com/YOUR_ORG/AdaptiveSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Adaptive' => 'dev@adaptive.com' }
  s.source           = { :git => 'https://github.com/YOUR_ORG/AdaptiveSDK.git', :tag => s.version.to_s }

  s.swift_version          = '5.9'
  s.ios.deployment_target  = '15.0'

  s.dependency 'AdaptiveCore',      '~> 1.0'
  s.dependency 'AdaptiveAnalytics', '~> 1.0'
  s.dependency 'AdaptiveMessaging', '~> 1.0'

end
