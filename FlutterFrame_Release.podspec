
Pod::Spec.new do |s|
	s.name = 'FlutterFrame_Release'
	s.version = '0.1'
	s.description = 'Flutter Release 模式静态包'
	s.license = 'MIT'
	s.summary = 'FlutterFrame_Release'
	s.homepage = 'https://xxx/LYFlutter'
	s.authors = { 'xyz' => 'x@y.com' }
	s.source = { :git => 'git@xxx/LYFlutter.git', :branch => 'master' }
	s.requires_arc = true
	s.ios.deployment_target = '8.0'

    s.vendored_frameworks = 'Flutter_Release/Flutter.framework', 'Flutter_Release/App.framework'
    s.resources = 'Flutter_Release/flutter_assets'

end
