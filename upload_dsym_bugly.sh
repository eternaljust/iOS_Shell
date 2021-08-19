#!/bin/bash

# https://bugly.qq.com/docs/user-guide/symbol-configuration-ios/?v=20210812174918
# 脚本需要 Java 运行时环境，Bugly 符号表工具上传工具包仅支持 jdk1.8.0，运行环境不支持时会提示是否前往官网下载安装。
# 可将 Bugly 后台的 App ID【appid】、App Key【appkey】以及应用的 Bundle identifier【bundleid】填入下方对应的字符串变量中，避免每次输入。
# dSYM 文件处理上传过程无打印日志，会在处理完结果后统一打印输出。

appid=""
appkey=""
bundleid=""
version=""
inputSymbol=""

open_download_jdk() {
  url="https://www.java.com/zh-CN/download/"
  echo -e "\033[33m 是否打开官网(${url})下载安装 jdk1.8.0？[y/n]： \033[0m"
  read open
  if [[ ${open} == 'y' || ${open} == 'Y' ]]; then
    open ${url}
  fi
  exit
}

check_jdk() {
  installed=`java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}'`
  if [[ ${installed} == "couldn’t" ]]; then
    echo -e "\033[31m 当前Mac没有Java运行时环境 \033[0m"
    open_download_jdk
  elif [[ ${installed} =~ "1.8.0" ]]; then
    echo -e "\033[35m 当前Mac已安装jdk1.8.0 \033[0m"
  else
    echo -e "\033[31m Bugly符号表工具上传工具包仅支持jdk1.8.0 \033[0m"
    open_download_jdk
  fi
}

check_dsym_code() {
  result=0
  if [[ -z ${inputSymbol} ]]; then
    result=1
  elif [[ ${inputSymbol} =~ " " ]]; then
    result=2
  elif [[ ! ${inputSymbol} =~ ".dSYM" ]]; then
    result=3
  fi
  echo ${result}
}

hour_minute_second() {
  second=$1
  if [[ ${second} -lt 60 ]]; then
    echo "${second}秒"
  elif [[ ${second} -lt 3600 ]]; then
    echo "$(( ${second} / 60 ))分/$(( ${second} % 60 ))秒"
  elif [[ ${second} -ge 3600 ]]; then
    echo "$(( ${second} / 3600 ))时/$(( (${second} % 3600) / 60 ))分/$(( (${second} % 3600) % 60 ))秒"
  fi
}

input_output_dsymfile() {
  if [[ $(check_dsym_code) != 0 ]]; then
      while [[ $(check_dsym_code) != 0 ]]; do
        case $(check_dsym_code) in
        1) echo -e "\033[31m 待上传dSYM文件路径为空！ \033[0m" ;;
        2) echo -e "\033[31m dSYM文件路径中文件夹名或文件名包含\" \"空格！请处理后重试 \033[0m" ;;
        3) echo -e "\033[31m 请确认待上传为dSYM文件！ \033[0m" ;;
        esac

        echo -e "\033[33m 请输入dSYM文件的路径或者将dSYM文件拖拽到此处： \033[0m"
        read inputSymbol
      done
  fi

  echo -e "\033[32m 待上传dSYM文件格式正确！路径为:${inputSymbol} \033[0m"
}

input_output_appid() {
  if [[ -z ${appid} ]]; then
    while [[ -z ${appid} ]]; do
      echo -e "\033[33m 请输入appid：\033[0m"
      read appid
    done
  fi

  echo -e "\033[32m 已提供APP ID of Bugly！ \033[0m"
}

input_output_appkey() {
  if [[ -z ${appkey} ]]; then
    while [[ -z ${appkey} ]]; do
      echo -e "\033[33m 请输入appkey：\033[0m"
      read appkey
    done
  fi

  echo -e "\033[32m 已提供APP Key of Bugly！ \033[0m"
}

input_output_bundleid() {
  if [[ -z ${bundleid} ]]; then
    while [[ -z ${bundleid} ]]; do
      echo -e "\033[33m 请输入bundleid：\033[0m"
      read bundleid
    done
  fi

  echo -e "\033[32m 已提供iOS平台 Bundle Id！ \033[0m"
}

input_output_version() {
  if [[ -z ${version} ]]; then
    while [[ -z ${version} ]]; do
      echo -e "\033[33m 请输入此dSYM文件的版本号version（如 1.0.0）: \033[0m"
      read version
    done
  fi

  echo -e "\033[32m 已提供APP版本，需要和bugly平台上面看到的crash版本号保持对齐！ \033[0m"
}

upload_dsym() {
  echo -e "\033[32m dSYM文件开始处理上传...... \033[0m"

  upload_start_time=$(date +'%s')
  upload=`java -jar buglyqq-upload-symbol.jar -appid ${appid} -appkey ${appkey} -bundleid ${bundleid} -version ${version} -platform IOS -inputSymbol ${inputSymbol} --verbose ;echo $?`
  upload_code=${upload:0-1}
  upload_end_time=$(date +'%s')
  upload_time=$(( ${upload_end_time} - ${upload_start_time} ))
  echo -e "\033[35m 处理上传结果: ${upload} \033[0m"

  if [[ ${upload} =~ "\"statusCode\":0" && ${upload_code} == 0 ]]; then
    echo -e "\033[32m dSYM文件上传成功！ \033[0m"
    echo -e "\033[33m 上传共耗时：$(hour_minute_second ${upload_time}) \033[0m"
  else
    echo -e "\033[31m 上传dSYM文件失败！请排查错误日志进行调整 \033[0m"
  fi
}

check_jdk
input_output_dsymfile
input_output_version
input_output_bundleid
input_output_appkey
input_output_appid
upload_dsym
