Pod::Spec.new do |s|
	s.name = 'LYFlutter'
	s.version = '0.1'
	s.description = 'Flutter 工程相关源代码 '
	s.license = 'MIT'
	s.summary = 'LYFlutter'
	s.homepage = 'https://xxx/LYFlutter'
	s.authors = { 'xyz' => 'x@y.com' }
	s.source = { :git => 'git@xxx/LYFlutter.git', :branch => 'master' }
	s.requires_arc = true
	s.ios.deployment_target = '8.0'

	s.dependency 'FlutterFrame_Release'
    s.dependency 'FlutterFrame_Debug'

    s.source_files = 'Source/**/*.{h,m,c}'
    s.public_header_files = 'Source/**/*.h'
    s.preserve_paths = 'PluginTool/pluginspodhelper.rb', 'Plugins/**/*.{*}', 'PluginTool/.flutter-plugins'

end
