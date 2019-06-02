#!/bin/sh

echo "###### $PWD ######"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=UTF-8
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:$HOME/Documents/flutter/bin

echo "flutter begin"
flutter packages get

echo "pod install or update"
cd ios
if [ ! -d "$PWD/Pods" ]; then
    pod install
else
    pod update
fi
cd -

echo "flutter debug -- 真机"
flutter clean
flutter build ios --no-codesign  --debug

res_dir=$PWD/ios/Flutter
source_res_dir=$PWD/ios/Source
source_runner_res_dir=$PWD/ios/Runner
flutter_res_plugins=$PWD/.flutter-plugins

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
target_plugins_dir=$target_dir/Plugins
target_pluginsTool_dir=$target_dir/PluginTool

target_debug_dir=$target_dir/Flutter
target_release_dir=$target_dir/Flutter_Release


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
cp -rf $source_res_dir .
cp {$source_runner_res_dir/GeneratedPluginRegistrant.h,$source_runner_res_dir/GeneratedPluginRegistrant.m} $target_source_dir

echo "copy plugins iOS source..."
if [ -d "$target_plugins_dir" ]; then
  rm -rf $target_plugins_dir
fi

if [ -f "$target_pluginsTool_dir/.flutter-plugins" ]; then
   rm -rf $target_pluginsTool_dir/.flutter-plugins
fi

if [ -f "$flutter_res_plugins" ]; then
    echo "flutter_res_plugins $flutter_res_plugins"
    cp -rf $flutter_res_plugins $target_pluginsTool_dir
fi

echo "flutter debug -- 模拟器"

cd -
flutter clean
flutter build ios --simulator  --debug
lipo -info $res_dir/App.framework/App
cd -

echo "合并 App.framework 的 真机及模拟器"
lipo -create $res_dir/App.framework/App $target_debug_dir/App.framework/App -output $target_debug_dir/App.framework/App

echo "打印下debug支持的平台"
lipo -info $target_debug_dir/App.framework/App
lipo -info $target_debug_dir/Flutter.framework/Flutter

# Plugin Pods
while read -r line
  do
    if [[ ! "$line" =~ ^// && ! "$line" =~ ^# ]]; then
      array=(${line//=/ })

      iosClasses=${array[1]}ios/Classes
      plugin=$target_plugins_dir/${array[0]}
      if [ -d $plugin ]; then
        rm -rf $plugin
      fi

      if [ -d $iosClasses ]; then
        mkdir -p $plugin
        cp -rf $iosClasses $plugin

        podspec=${array[1]}ios/${array[0]}.podspec
        if [ -d $iosClasses ]; then
            cp -f $podspec $plugin
            podspec=$plugin/${array[0]}.podspec
            echo "删除 s.dependency 'Flutter' in $podspec"
#            sed -i '' -e "s/s.dependency 'Flutter'//g" $podspec
            gsed  -i "s/s.dependency 'Flutter'/s.dependency 'FlutterFrame_Release' \n  s.dependency 'FlutterFrame_Debug'/g" $podspec
        fi

        echo "plugin $plugin"
        echo "iosClasses $iosClasses"
      fi
    fi
  done < $flutter_res_plugins

echo "flutter release -- 真机"
cd -
flutter clean
flutter build ios --no-codesign --release
cd -

if [ -d "$target_release_dir" ]; then
rm -rf $target_release_dir
fi
mkdir -p $target_release_dir
echo "copy framework release..."
cp -R $res_dir/* $target_release_dir

echo "打印下release支持的平台"
lipo -info $target_release_dir/App.framework/App
lipo -info $target_release_dir/Flutter.framework/Flutter

git add .
git commit -m "auto commit"
git push origin master
cd -
