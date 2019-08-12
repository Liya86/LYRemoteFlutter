#!/bin/sh
set -e
echo "###### $PWD ######"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=UTF-8
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:$HOME/Documents/flutter/bin
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

delPodsepcDependency(){
  podPath=${1}
  gsed -i '/.dependency.*/d' $podPath
}

updatePodsepcVersion(){
  podPath=${1}
# s.version = '7.4.8.002' <-- 针对此种
# 7.4.8.002 -> 7.4.8.003 
# 7.4.8.999 -> 7.4.9.000 ⚠️ 7.4.8.0999 -> 7.4.8.1000 根据位数进位的
  while read -r line
    do
      if [[ "$line" =~ .version ]]; then
        array=(${line//"'"/ })
        index=`expr ${#array[@]} - 1`
        lastVersion=${array[$index]}
        echo "${line}   index=${index} lastVersion=${lastVersion}"
        newVersion=$(echo ${lastVersion} | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}') 
        echo "newVersion = ${newVersion}"
        gsed  -i "s/${line}/s.version='${newVersion}'/g" $podPath
     fi
    done < $podPath
}

pluginLibaryCollect(){
  echo "plugin 收集"
  res_plugins=${1}
  res_plugins_build=${2}
  target_plugins=${3}
  target_plagin_suffix=${4}

  while read -r line
    do
      if [[ ! "$line" =~ ^// && ! "$line" =~ ^# ]]; then
        array=(${line//=/ })
        pluginName=${array[0]}
        iosClasses=${array[1]}ios/Classes
        if [ -d $iosClasses ]; then
          plugin=$target_plugins/$pluginName
          if [ ! -d $plugin ]; then
            mkdir $plugin
          fi
          cp -R $res_plugins_build/$pluginName/lib${pluginName}.a $plugin/lib${pluginName}_${target_plagin_suffix}.a
        fi
     fi
    done < $res_plugins
}

pluginReleaseCollect(){
  echo "plugin 收集"
  res_plugins=${1}
  target_plugins_Releas=${2}

  while read -r line
    do
      if [[ ! "$line" =~ ^// && ! "$line" =~ ^# ]]; then
        array=(${line//=/ })
        pluginPath=${array[1]}ios
        iosClasses=${pluginPath}/Classes
        pluginName=${array[0]}

        echo "======== ${array[0]} Release 收集 ========"

        echo "== 命令封装 Release 静态库 ${array[0]}.a -> ${array[0]}.framework"
        plugin=$target_plugins_Releas/$pluginName
        cd $plugin

        mkdir -p $pluginName.framework/Versions/A/Headers
        mkdir -p $pluginName.framework/Versions/A/Resources
        echo "== 软链接"
        ln -s A $pluginName.framework/Versions/Current
        ln -s Versions/Current/Headers $pluginName.framework/Headers
        ln -s Versions/Current/Resources $pluginName.framework/Resources
        ln -s Versions/Current/$pluginName $pluginName.framework/$pluginName
        echo "== 合并"
        lipo -create \
            $plugin/lib${pluginName}_release_os.a \
            -o $pluginName.framework/Versions/A/$pluginName

        for header in `find "$iosClasses" -name *.h`; do
          cp -f $header $pluginName.framework/Versions/A/Headers/
        done
        rm -rf $plugin/lib${pluginName}_release_os.a

        echo "== podspec 提取，可能依赖了别的第三方"
        podspec=$pluginPath/$pluginName.podspec
        if [ -d $iosClasses ]; then
          cp -f $podspec $plugin
          podspec=$plugin/$pluginName.podspec
          echo "删除 s.dependency 'Flutter' in $podspec"
          gsed  -i "s/s.dependency 'Flutter'/s.dependency 'FlutterFrame_Release' \n  s.dependency 'FlutterFrame_Debug'/g" $podspec
        fi   
     fi
    done < $res_plugins
}

pluginDebugCollect(){
  echo "plugin 收集"
  res_plugins=${1}
  target_plugins_Debug=${2}

  while read -r line
    do
      if [[ ! "$line" =~ ^// && ! "$line" =~ ^# ]]; then
        array=(${line//=/ })
        pluginPath=${array[1]}ios
        iosClasses=${pluginPath}/Classes
        pluginName=${array[0]}

        echo "======== ${array[0]} debug 收集 ========"
        plugin=$target_plugins_Debug/$pluginName
        cd $plugin
          
        echo "== 命令封装 Debug 静态库 ${array[0]}.a -> ${array[0]}.framework"
        mkdir -p $pluginName.framework/Versions/A/Headers
        mkdir -p $pluginName.framework/Versions/A/Resources
        echo "== 软链接"
        ln -s A $pluginName.framework/Versions/Current
        ln -s Versions/Current/Headers $pluginName.framework/Headers
        ln -s Versions/Current/Resources $pluginName.framework/Resources
        ln -s Versions/Current/$pluginName $pluginName.framework/$pluginName
        echo "== 合并"
        lipo -create \
            $plugin/lib${pluginName}_debug_os.a \
            $plugin/lib${pluginName}_debug_simulator.a \
            -o $pluginName.framework/Versions/A/$pluginName

        for header in `find "$iosClasses" -name *.h`; do
        cp -f $header $pluginName.framework/Versions/A/Headers/
        done
        rm -rf $plugin/lib${pluginName}_debug_os.a
        rm -rf $plugin/lib${pluginName}_debug_simulator.a

        echo "== podspec 提取，可能依赖了别的第三方"
        podspec=$pluginPath/$pluginName.podspec
        if [ -d $iosClasses ]; then
          cp -f $podspec $plugin
          podspec=$plugin/$pluginName.podspec
          echo "删除 s.dependency 'Flutter' in $podspec"
          gsed  -i "s/s.dependency 'Flutter'/s.dependency 'FlutterFrame_Release' \n  s.dependency 'FlutterFrame_Debug'/g" $podspec
        fi   
     fi
    done < $res_plugins
}

echo "flutter begin"
flutter packages get

echo "pod install or update"
cd ios
if [ ! -d "$PWD/Pods" ]; then
    pod install
else
    pod update --verbose --no-repo-update
fi
cd -

echo "flutter debug -- 真机"
flutter clean
flutter build ios --debug --no-simulator

res_application=$PWD
res_build=$PWD/build
res_dir=$PWD/ios/Flutter
res_source_dir=$PWD/ios/Source
res_source_runner_dir=$PWD/ios/Runner
res_flutter_plugins=$PWD/.flutter-plugins

echo "git clone or pull LYFlutter...(地址自行调整)"
if [ ! -d "../LYFlutter" ]; then
    git clone git@.../LYFlutter.git ../LYFlutter
    cd ../LYFlutter
else
    cd ../LYFlutter
    git pull
fi
git checkout master

target_dir=$PWD
target_source_dir=$target_dir/Source
target_debug_dir=$target_dir/Flutter_Debug
target_debug_plugins_dir=$target_debug_dir/Plugins
target_release_dir=$target_dir/Flutter_Release
target_release_plugins_dir=$target_release_dir/Plugins

echo "copy framework to Flutter..."
if [ -d "$target_debug_dir" ]; then
    rm -rf $target_debug_dir
fi
mkdir -p $target_debug_dir
cp -R $res_dir/* $target_debug_dir

echo "copy iOS business Source..."
if [ -d "$target_source_dir" ]; then
   rm -rf $target_source_dir
fi
cp -rf $res_source_dir .
cp {$res_source_runner_dir/GeneratedPluginRegistrant.h,$res_source_runner_dir/GeneratedPluginRegistrant.m} $target_source_dir

echo "del plugins iOS source..."
if [ -d "$target_debug_plugins_dir" ]; then
  rm -rf $target_debug_plugins_dir
fi
mkdir -p $target_debug_plugins_dir

pluginLibaryCollect $res_flutter_plugins $res_build/ios/Debug-iphoneos $target_debug_plugins_dir "debug_os"

echo "flutter debug -- 模拟器"

cd $res_application
flutter clean
flutter build ios --debug --simulator
lipo -info $res_dir/App.framework/App
cd $target_dir

echo "合并 App.framework 的 真机及模拟器"
lipo -create $res_dir/App.framework/App $target_debug_dir/App.framework/App -output $target_debug_dir/App.framework/App

echo "打印下debug支持的平台"
lipo -info $target_debug_dir/App.framework/App
lipo -info $target_debug_dir/Flutter.framework/Flutter

pluginLibaryCollect $res_flutter_plugins $res_build/ios/Debug-iphonesimulator $target_debug_plugins_dir "debug_simulator"
delPodsepcDependency $target_dir/FlutterFrame_Debug.podspec
pluginDebugCollect $res_flutter_plugins $target_debug_plugins_dir

echo "flutter release -- 真机"
cd $res_application
flutter clean
flutter build ios --release --no-simulator
cd $target_dir

if [ -d "$target_release_dir" ]; then
rm -rf $target_release_dir
fi
mkdir -p $target_release_dir
echo "copy framework release..."
cp -R $res_dir/* $target_release_dir

echo "打印下release支持的平台"
lipo -info $target_release_dir/App.framework/App
lipo -info $target_release_dir/Flutter.framework/Flutter

echo "del release plugins iOS source..."
if [ -d "$target_release_plugins_dir" ]; then
rm -rf $target_release_plugins_dir
fi
mkdir -p $target_release_plugins_dir

pluginLibaryCollect $res_flutter_plugins $res_build/ios/Release-iphoneos $target_release_plugins_dir "release_os"
delPodsepcDependency $target_dir/FlutterFrame_Release.podspec
pluginReleaseCollect $res_flutter_plugins $target_release_plugins_dir

updatePodsepcVersion $target_dir/LYFlutter.podspec
updatePodsepcVersion $target_dir/FlutterFrame_Debug.podspec
updatePodsepcVersion $target_dir/FlutterFrame_Release.podspec

cd $target_dir
git add .
git commit -m "auto commit"
git push origin master
cd -
