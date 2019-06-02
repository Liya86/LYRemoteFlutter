
Pod::Spec.new do |s|
	s.name = 'FlutterFrame_Debug'
	s.version = '0.1'
	s.description = 'Flutter Debug 模式静态包'
	s.license = 'MIT'
	s.summary = 'FlutterFrame_Debug'
	s.homepage = 'https://xxx/LYFlutter'
	s.authors = { 'xyz' => 'x@y.com' }
	s.source = { :git => 'git@xxx/LYFlutter.git', :branch => 'master' }
	s.requires_arc = true
	s.ios.deployment_target = '8.0'

    s.vendored_frameworks = 'Flutter/Flutter.framework', 'Flutter/App.framework'
    s.resources = 'Flutter/flutter_assets'

end