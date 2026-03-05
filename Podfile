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

  # CocoaPods can set this to YES in aggregate target xcconfigs (Pods-*.xcconfig),
  # which breaks static library pod targets with a PhaseScriptExecution error.
  Dir.glob(File.join(installer.sandbox.root.to_s, 'Target Support Files', 'Pods-*', '*.xcconfig')).each do |xcconfig_path|
    content = File.read(xcconfig_path)
    updated = content.gsub(/^ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES\s*=\s*YES$/, 'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO')
    File.write(xcconfig_path, updated) if updated != content
  end

  # Update Pods project-level settings to recommended values
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
    config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++20'
  end

  # Prevent recurring "Update to recommended settings" prompts in Pods.xcodeproj
  installer.pods_project.root_object.attributes['LastUpgradeCheck'] = '1620'
  installer.pods_project.root_object.attributes['LastSwiftUpdateCheck'] = '1620'
end
