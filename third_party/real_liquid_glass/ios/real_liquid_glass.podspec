#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint real_liquid_glass.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'real_liquid_glass'
  s.version          = '0.3.0'
  s.summary          = 'Native Liquid Glass containers and tab bars for Flutter.'
  s.description      = <<-DESC
Hosts Apple's native Liquid Glass material and UITabBar behind Flutter APIs.
                       DESC
  s.homepage         = 'https://github.com/kiddo4/real_liquid_glass'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Taiwo Olanrewaju' => 'olanrewajutaiwo183@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'real_liquid_glass/Sources/real_liquid_glass/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'real_liquid_glass_privacy' => ['real_liquid_glass/Sources/real_liquid_glass/PrivacyInfo.xcprivacy']}
end
