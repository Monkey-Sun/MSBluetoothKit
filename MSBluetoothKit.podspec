Pod::Spec.new do |s|
  s.name         = "MSBluetoothKit"
  s.module_name  = "MSBluetoothKit"
  s.version      = "1.0.0"
  s.summary      = "Bluetooth manager on iOS 10 or later."
  s.description  = "An easy way to use bluetooth, support iOS 10 or later"
  s.homepage     = "https://github.com/Smiacter/TouchIdManager"
  s.license      = "MIT"
  s.author             = { "MonkeySun" => "492899051@qq.com" }
  s.platform     = :ios
  s.platform     = :ios, "11.0"
  s.swift_version = "4.2"
  s.source       = { :git => "https://github.com/Monkey-Sun/MSBluetoothKit.git", :tag => "#{s.version}" }
  s.source_files  = "MSBluetoothKit/Sources/*.swift"
end
