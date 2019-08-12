# LYFlutter
### 产物收集脚本情况
1. 路径相关需自行改动哟 ～～ 

### 按这个方式进行的Flutter远程及本地依赖的话，使用如下
1. 下载 PluginTool 下的 FlutterPodHelper.rb 脚本放置 主工程 
2. 远程依赖 - debug/release的产物
```
# flutter远程依赖 
# $flutter_podspec_path ： LYFlutter的远程podspec路径，可在脚本设置后，这里一般可不设置，默认：
#    https://.../LYFlutter/raw/master
    eval(File.read(File.join(__dir__, 'FlutterPodHelper.rb')), binding)
```
3. 本地依赖 - 依赖本地 flutter 工程的产物
```
# flutter本地依赖 
# $flutter_application_path ： flutter工程的路径
    $flutter_application_path = "/Users/xxx/ly_flutter"
    eval(File.read(File.join(__dir__, 'FlutterPodHelper.rb')), binding)
```
4. post_install hook
```
post_install do |installer|
#调用配置 - bitcode设置
    update_flutter_configs(installer, $flutter_application_path)
end
```
### 若是只需进行远程依赖
```
pod 'LYFlutter', :podspec => "http://.../LYFlutter.podspec"
pod 'Flutter_Debug', :podspec => "http://.../Flutter_Debug.podspec", :configurations => ['Debug']
pod 'Flutter_Release', :podspec => "http://.../Flutter_Release.podspec", :configurations => ['Release']
```

### 说明
1. 这只是一个远程/本地依赖的操作方式，若有更好的实现方法，请提 issues 哟～～
[Flutter远程依赖简单实践](https://www.jianshu.com/p/c010bdd6a926)  
[Flutter远程组件最佳实践](https://www.jianshu.com/p/27c312548c2c)

2. Debug 模式及 Release 模式分别对应一个 podsepc 进行引用，可以解决 开发模式 调试 及 发包时 ci 打包发布模式 需要手动切换的麻烦，有一些播放器也是 Debug 跟 Release模式各一个静态包，也同样可以以这种方式来减少手动切换操作（已实验过，👌）
 (  PS 这个如果有更好的 framework search paht 设置及 flutter_assets 资源路径设置方法，请提 issues ，之前尝试过直接在 podfile 中设置，依然存在各种问题 ）
```
pod 'LYFlutter', :git => liya_flutter_git_url, :branch => branch
pod 'FlutterFrame_Debug', :git => liya_flutter_git_url, :branch => branch, :configurations => 'Debug'
pod 'FlutterFrame_Release', :git => liya_flutter_git_url, :branch => branch, :configurations => 'Release'
```
