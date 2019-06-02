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

# 远程的plugins文件解析
def pod_remote_flugins_file(plugin_helper_local_path, pod_file)
    # If this wasn't specified, assume it's two levels up from the directory of this script.
    print "解析并写入pod plugin \n"
    plugin_pods_file = parse_KV_file(File.join(plugin_helper_local_path))
    plugin_pods_file.map { |r|
        print "plugin_pods_file = ",r[:name]," \n"
        pod r[:name], :path => File.join(pod_file, 'LYFlutter/Plugins', r[:name])
    }
end

# 远程的plugins文件下载并解析
def down_remote_plugins_file(branch, pod_file)
    liya_flutter_url = "https:xxxx/iOS/LYFlutter"
    liya_flutter_git_url = liya_flutter_url+".git"
    plugin_helper_url = liya_flutter_url+"/raw/"+branch+"/PluginTool/.flutter-plugins"
    
    plugin_helper_local_path = './.flutter-plugins'
    
    print "下载 plugins 解析文件 \n"
    download = open(plugin_helper_url)
    IO.copy_stream(download, plugin_helper_local_path)
    
    pod 'LYFlutter', :git => liya_flutter_git_url, :branch => branch
    pod 'FlutterFrame_Debug', :git => liya_flutter_git_url, :branch => branch, :configurations => 'Debug'
    pod 'FlutterFrame_Release', :git => liya_flutter_git_url, :branch => branch, :configurations => 'Release'
    
    pod_remote_flugins_file(plugin_helper_local_path, pod_file)
    
    File.delete(plugin_helper_local_path)
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

# branch-分支的名称，主工程的pods路径
#down_remote_plugins_file("feature/liya_test_2", __dir__+"/Pods")

# 本地 flutter 工程的路径
#local_remote_plugins_file("/Users/.../liya_flutter")

if !$flutter_pod_path.nil?
    if $flutter_branch.nil?
        $flutter_branch = "master"
    end
    down_remote_plugins_file($flutter_branch, $flutter_pod_path)
elsif !$flutter_application_path.nil?
    local_remote_plugins_file($flutter_application_path)
else
    raise "请正确输入 远程依赖的分支名称（默认master）及 主工程的pods路径 \n 或者 请正确输入 本地依赖的本地 flutter 工程的路径 \n"
end
