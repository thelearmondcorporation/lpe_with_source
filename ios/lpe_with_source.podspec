Pod::Spec.new do |s|
  s.name         = 'lpe_with_source'
  s.version      = '0.0.2+1'
  s.summary      = 'Learmond Pay Element (LPE) with Source - cross-platform paysheet and native pay helper '
  s.homepage     = 'https://thelearmondcorporation.com'
  s.license      = { :file => '../LICENSE' }
  s.author       = { 'Learmond' => 'support@thelearmondcorporation.com' }
  s.platform     = :ios, '11.0'
  s.source       = { :path => '.' }
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
end
