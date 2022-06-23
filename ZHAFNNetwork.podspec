
Pod::Spec.new do |s|
  s.name             = 'ZHAFNNetwork'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ZHAFNNetwork.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/zhanghua19860221/ZHAFNNetwork'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhanghua' => '3051942353@qq.com' }
  s.source           = { :git => 'https://github.com/zhanghua19860221/ZHAFNNetwork.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'ZHAFNNetwork/Classes/**/*'
  s.dependency 'YYCache', '1.0.4'
  s.dependency 'AFNetworking', '4.0.1'

end
