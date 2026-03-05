platform :ios, '16.0'

target 'GoFit.Ai - live Healthy' do
  pod 'Google-Mobile-Ads-SDK', '~> 13.0'
  pod 'GoogleUserMessagingPlatform', '~> 1.0'
end

target 'GoFit.Ai - live HealthyTests' do
end

target 'GoFit.Ai - live HealthyUITests' do
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
    end
  end

  # Update Pods project-level settings to recommended values
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
    config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++20'
  end
end
