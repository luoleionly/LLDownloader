
Pod::Spec.new do |s|
  s.name             = 'LLDownloader'
  s.version          = '3.2.10'
  s.summary          = 'Objective-C port of LL, a lightweight download framework.'

  s.homepage         = 'https://github.com/Danie1s/LL'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Daniels' => '176516837@qq.com' }
  s.source           = { :git => 'https://github.com/Danie1s/LL.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files  = '{General,Extensions,Utility}/**/*.{h,m}', 'LLDownloader.h'
  s.public_header_files = '{General,Extensions,Utility}/**/*.h', 'LLDownloader.h'
  s.frameworks    = 'Foundation', 'UIKit'
  s.requires_arc  = true

end
