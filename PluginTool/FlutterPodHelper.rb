require 'open-uri'

def parse_KV_file(file, separator='=')
    file_abs_path = File.expand_path(file)
    if !File.exists? file_abs_path
        return [];
    end
    pods_array = []
    skip_line_start_symbols = ["#", "/"]
    File.foreach(file_abs_path) { |line|
        next if skip_line_start_symbols.any? { |symbol| line =~ /^\s*#{symbol}/ }
        plugin = line.split(pattern=separator)
        if plugin.length == 2
            podname = plugin[0].strip()
            path = plugin[1].strip()
            podpath = File.expand_path("#{path}", file_abs_path)
            pods_array.push({:name => podname, :path => podpath});
            else
            puts "Invalid plugin specification: #{line}"
        end
    }
    return pods_array
end

# 远程的plugins文件下载并解析
def down_remote_plugins_file(podspecPath)
    lyflutter_path = podspecPath+'/LYFlutter.podspec'
    flutter_debug_path = podspecPath+'/FlutterFrame_Debug.podspec'
    flutter_release_path = podspecPath+'/FlutterFrame_Release.podspec'
    pod 'LYFlutter', :podspec => lyflutter_path
    pod 'FlutterFrame_Debug', :podspec => flutter_debug_path, :configurations => ['Debug']
    pod 'FlutterFrame_Release', :podspec => flutter_release_path, :configurations => ['Release']
end

# 设置flutter_application_path（本地 flutter 的项目路径）， 传nil即只进行bitcode处理（远程时）
# Ensure that ENABLE_BITCODE is set to NO, add a #include to Generated.xcconfig, and
# add a run script to the Build Phases.
def update_flutter_configs(installer, flutter_application_path)
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            if !flutter_application_path.nil?
                xcconfig_path = config.base_configuration_reference.real_path
                File.open(xcconfig_path, 'a+') do |file|
                    file.puts "#include \"#{File.realpath(File.join(flutter_application_path, 'ios', 'Flutter', 'Generated.xcconfig'))}\""
                end
            end
        end
    end
end

# 本地的引用
def local_remote_plugins_file(flutter_application_path)
    native_application_path = File.join(flutter_application_path, 'ios')
    framework_dir = File.join(native_application_path, 'Flutter')
    
    pod 'Flutter', :path => native_application_path
    pod 'LYFlutter', :path => native_application_path
    
    symlinks_dir = File.join(native_application_path, '.symlinks')
    FileUtils.mkdir_p(symlinks_dir)
    plugin_pods = parse_KV_file(File.join(flutter_application_path, '.flutter-plugins'))
    plugin_pods.map { |r|
        symlink = File.join(symlinks_dir, 'plugins', r[:name])
        FileUtils.rm_f(symlink)
        File.symlink(r[:path], symlink)
        pod r[:name], :path => File.join(symlink, 'ios')
    }
end

# flutter_podspecPath-引用的flutter的podspec路径，默认如下
#down_remote_plugins_file("https://.../LYFlutter/raw/master")

# 本地 flutter 工程的路径
#local_remote_plugins_file("/Users/.../liya_flutter")

if !$flutter_application_path.nil?
    local_remote_plugins_file($flutter_application_path)
else
    if $flutter_podspec_path.nil?
        $flutter_podspec_path = "https://.../LYFlutter/raw/master"
    end
    down_remote_plugins_file($flutter_podspec_path)
end
