Pod::Spec.new do |s|

  s.name             = 'AdaptiveMessaging'
  s.version          = '1.0.0'
  s.summary          = 'Messaging module for AdaptiveSDK — FCM push notification sync and display.'

  s.homepage         = 'https://github.com/YOUR_ORG/AdaptiveSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Adaptive' => 'dev@adaptive.com' }
  s.source           = { :git => 'https://github.com/YOUR_ORG/AdaptiveSDK.git', :tag => s.version.to_s }

  s.swift_version          = '5.9'
  s.ios.deployment_target  = '15.0'

  s.source_files       = 'Sources/AdaptiveSDK/AdaptiveMessaging/Sources/AdaptiveMessaging/**/*.swift'
  s.dependency           'AdaptiveCore', '~> 1.0'
  s.ios.frameworks     = 'UserNotifications'

end
