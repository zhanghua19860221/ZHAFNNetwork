
Pod::Spec.new do |s|
  s.name             = 'ZHAFNNetwork'
  s.version          = '0.2.2'
  s.summary          = '网络库 ZHAFNNetwork'

  s.homepage         = 'https://github.com/zhanghua19860221/ZHAFNNetwork'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhanghua' => '3051942353@qq.com' }
  s.source           = { :git => 'https://github.com/zhanghua19860221/ZHAFNNetwork.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  
  s.source_files = 'ZHAFNNetwork/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ZHAFNNetwork' => ['ZHAFNNetwork/Assets/*.png']
  # }
  
  s.dependency 'YYCache'
  s.dependency 'AFNetworking'

end
