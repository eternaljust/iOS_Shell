#!/bin/bash

# https://help.apple.com/asc/appsaltool/
# https://zh-google-styleguide.readthedocs.io/en/latest/google-shell-styleguide/contents/

# 使用该脚本的步骤说明如下：
# 1.使用开发者账号访问 https://appstoreconnect.apple.com 登录 App Store Connect 首页，点击【用户与访问】
# 2.选择【密钥】生成 API p8 密钥下载保存（只能下载一次）
# 3.在终端复制执行【cd ~ && mkdir .private_keys】创建隐藏文件夹，再将下载的 p8 文件复制或移动到用户根目录下的指定路径【.private_keys】隐藏文件夹下
# 4.快捷键【command + shift + .】可查看显示隐藏文件夹文件
# 5.可将后台生成的密钥 ID【apiKey】和 Issuer ID【apiIssuer】添入下方对应的字符串变量中（ipa_filepath="" api_key=""），避免每次输入
# 6.该脚本会调用【iTMSTransporter】组件进行上传，若本机电脑【~/Library/Caches/com.apple.amp.itmstransporter】文件夹没有缓存则会下载一组 jar 工具包
# 7.也可单独执行【/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/itms/bin/iTMSTransporter】来下载缓存（正常下载完成文件夹大约50～60MB，上传过程有缓存记录，文件夹大小会增加）
# 8.如果日志打印显示上传的进度值变化比较小，上传缓慢等待时间比较久，可尝试切换连接手机热点重试
# 9.重要的函数为【input_output_ipafilepath】和【validate_upload_ipa】，填写好【api_key】和【api_issuer】后，也可注释掉对应的调用方法函数
# 10.【cd 到该脚本的文件夹下】再执行【./upload_ipa.sh】，可将待上传的【ipa文件】直接拖到终端输入提示中，再回车确认

ipa_filepath=""
api_key=""
api_issuer=""

check_xcode_command_line_tool() {
  while [[ $(xcode-select -p 1>/dev/null;echo $?) != 0 ]]; do
    echo -e "\033[31m 命令行开发者工具未安装！ \033[0m"
    if [[ ! -d "/Library/Developer/CommandLineTools" ]]; then
      xcode-select --install
    else
      sudo xcode-select --switch /Applications/Xcode.app
    fi
  done
}

check_ipa_code() {
  result=0
  if [[ -z ${ipa_filepath} ]]; then
    result=1
  elif [[ ! -f ${ipa_filepath} ]]; then
    result=2
  elif [[ ${ipa_filepath} =~ " " ]]; then
    result=3
  elif [[ ! ${ipa_filepath} =~ ".ipa" ]]; then
    result=4
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

input_output_ipafilepath() {
  if [[ $(check_ipa_code) != 0 ]]; then
      while [[ $(check_ipa_code) != 0 ]]; do
        case $(check_ipa_code) in
        1) echo -e "\033[31m 待上传ipa文件路径为空！ \033[0m" ;;
        2) echo -e "\033[31m 待上传ipa文件不存在！ \033[0m" ;;
        3) echo -e "\033[31m ipa文件路径中文件夹名或文件名包含\" \"空格！请处理后重试 \033[0m" ;;
        4) echo -e "\033[31m 请确认待上传为ipa文件！ \033[0m" ;;
        esac
        
        echo -e "\033[33m 请输入ipa文件的路径或者将ipa文件拖拽到此处： \033[0m"
        read ipa_filepath
      done
  fi

  echo -e "\033[32m 待上传ipa文件格式正确！路径为:${ipa_filepath} \033[0m"
}

input_output_apikey() {
  if [[ -z ${api_key} ]]; then
    while [[ -z ${api_key} ]]; do
      echo -e "\033[33m 请输入apiKey：\033[0m"
      read api_key
    done
  fi
  
  echo -e "\033[32m 已提供API密钥（密钥ID）！ \033[0m"
}

input_output_apiissuer() {
  if [[ -z ${api_issuer} ]]; then
    while [[ -z ${api_issuer} ]]; do
      echo -e "\033[33m 请输入apiIssuer： \033[0m"
      read api_issuer
    done
  fi
  
  echo -e "\033[32m 已提供API发放者信息（Issuer ID）! \033[0m"
}

validate_upload_ipa() {
  echo -e "\033[33m ipa文件开始验证...... \033[0m"
  validate_start_time=$(date +'%s')
  validate=`xcrun altool --validate-app -f ${ipa_filepath} -t ios --apiKey ${api_key} --apiIssuer ${api_issuer} --verbose ;echo $?`
  validate_end_time=$(date +'%s')
  validate_time=$(( ${validate_end_time} - ${validate_start_time} ))
  echo -e "\033[33m 验证共耗时：$(hour_minute_second ${validate_time}) \033[0m"
  echo -e "\033[34m 验证结果: ${validate} \033[0m"
  validate_code=${validate:0-1}
  
  if [[ ${validate_code} == 1 ]]; then
    echo -e "\033[31m 验证ipa文件失败！请排查错误日志进行调整 \033[0m"
  else
    echo -e "\033[32m ipa文件验证成功！准备开始上传...... \033[0m"
    
    upload_start_time=$(date +'%s')
    upload=`xcrun altool --upload-app -f ${ipa_filepath} -t ios --apiKey ${api_key} --apiIssuer ${api_issuer} --verbose ;echo $?`
    upload_end_time=$(date +'%s')
    upload_time=$(( ${upload_end_time} - ${upload_start_time} ))
    echo -e "\033[33m 上传共耗时：$(hour_minute_second ${upload_time}) \033[0m"
    echo -e "\033[34m 上传结果: ${upload} \033[0m"
    upload_code=${upload:0-1}

    if [[ ${upload_code} == 1 ]]; then
      echo -e "\033[31m 上传ipa文件失败！请排查错误日志进行调整 \033[0m"
    else
      total_time=$(( ${validate_time} + ${upload_time} ))
      echo -e "\033[33m ipa文件验证和上传共耗时：$(hour_minute_second ${total_time}) \033[0m"
      echo -e "\033[32m ipa文件上传成功！ \033[0m"
    fi
  fi
}

check_xcode_command_line_tool
input_output_ipafilepath
input_output_apikey
input_output_apiissuer
validate_upload_ipa
