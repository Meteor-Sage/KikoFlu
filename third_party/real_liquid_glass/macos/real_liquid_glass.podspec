Pod::Spec.new do |s|
  s.name             = 'real_liquid_glass'
  s.version          = '0.3.0'
  s.summary          = 'Native Liquid Glass containers for Flutter (macOS).'
  s.description      = <<-DESC
Hosts Apple's NSGlassEffectView Liquid Glass material behind Flutter content.
                       DESC
  s.homepage         = 'https://github.com/kiddo4/real_liquid_glass'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Taiwo Olanrewaju' => 'olanrewajutaiwo183@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'real_liquid_glass/Sources/real_liquid_glass/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
