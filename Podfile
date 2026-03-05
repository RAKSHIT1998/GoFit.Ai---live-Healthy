platform :ios, '13.0'

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
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
    end
  end
end
