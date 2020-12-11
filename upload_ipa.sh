#!/bin/bash

# https://help.apple.com/asc/appsaltool/
# https://zh-google-styleguide.readthedocs.io/en/latest/google-shell-styleguide/contents/

# 开发者账号访问 https://appstoreconnect.apple.com 登录 App Store Connect 首页，点击【用户与访问】
# 选择【密钥】生成 API p8 密钥下载保存（只能下载一次）
# 【cd ~ && mkdir .private_keys】创建隐藏文件夹，再将下载的 p8 文件放到用户根目录下的指定路径【.private_keys】隐藏文件夹下
# 【command + shift + .】可查看显示隐藏文件夹文件
# 可将生成的密钥 ID【apiKey】和 Issuer ID【apiIssuer】添入下方对应的字符串变量中，避免每次输入
# 若【~/Library/Caches/com.apple.amp.itmstransporter】文件夹没有缓存则会下载一组 jar 包，也可单独执行【/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/itms/bin/iTMSTransporter】来下载缓存（正常下载完成文件夹大约50～60MB）
# 如果日志打印显示上传的进度值变化比较小，上传缓慢等待时间比较久，可尝试切换连接手机热点重试

ipa_file=""
api_key=""
api_issuer=""

check_ipa_code() {
  result=0
  if [[ -z ${ipa_file} ]]; then
    result=1
  elif [[ ! -f ${ipa_file} ]]; then
    result=2
  elif [[ ${ipa_file} =~ " " ]]; then
    result=3
  elif [[ ! ${ipa_file} =~ ".ipa" ]]; then
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

input_output_ipafile() {
  if [[ $(check_ipa_code) != 0 ]]; then
      while [[ $(check_ipa_code) != 0 ]]; do
        case $(check_ipa_code) in
        1) echo -e "\033[31m 待上传ipa文件路径为空！ \033[0m" ;;
        2) echo -e "\033[31m 待上传ipa文件不存在！ \033[0m" ;;
        3) echo -e "\033[31m ipa文件路径中文件夹名或文件名包含\" \"空格！请处理后重试 \033[0m" ;;
        4) echo -e "\033[31m 请确认待上传为ipa文件！ \033[0m" ;;
        esac
        
        echo -e "\033[33m 请输入ipa文件的路径或者将ipa文件拖拽到此处： \033[0m"
        read ipa_file
      done
  fi

  echo -e "\033[32m 待上传ipa文件格式正确！路径为:${ipa_file} \033[0m"
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
  validate=`xcrun altool --validate-app -f ${ipa_file} -t ios --apiKey ${api_key} --apiIssuer ${api_issuer} --verbose ;echo $?`
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
    upload=`xcrun altool --upload-app -f ${ipa_file} -t ios --apiKey ${api_key} --apiIssuer ${api_issuer} --verbose ;echo $?`
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

input_output_ipafile
input_output_apikey
input_output_apiissuer
validate_upload_ipa
