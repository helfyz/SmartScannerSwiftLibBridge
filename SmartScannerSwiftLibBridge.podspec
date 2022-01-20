Pod::Spec.new do |s|

  s.name                  = 'SmartScannerSwiftLibBridge'
  s.version               = '0.0.1'
  s.summary               = 'SmartScanner Swift Lib Bridge'
  s.homepage              = 'https://wiki.connect.qq.com'
  s.ios.deployment_target = '11.0'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'helfy' => '562812743@qq.com' }
  s.social_media_url      = 'https://github.com/helfyz'
  s.source                = { :git => 'https://github.com/helfyz/SmartScannerSwiftLibBridge.git', :tag => s.version }
  s.source_files  = "Classes", "Classes/**/*"
  s.requires_arc          = true
  # 依赖库
  s.dependency 'SwiftyTesseract'
  s.dependency 'SwiftyStoreKit'
end
