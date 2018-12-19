#!/bin/bash

set -e

endpoint=$(cat ~/.fcli/config.yaml | grep 'endpoint' | awk -F ': ' '{print $2}' | sed '2d')
api_version=$(cat ~/.fcli/config.yaml | grep 'api_version' | awk -F '"' '{print $2}')
service_name="dingRobot"-$(date +%s | base64 | sed 's/=/a/g' | sed 's/&/b/g' |head -c 8 )
token=$(date +%s |base64 | sed 's/=/a/g' | sed 's/&/b/g')

trigger_url=$endpoint/$api_version/proxy/$service_name/sendMessage/

rm -rf function

mkdir function

cp urls.txt ./function
cp sendMessage.js ./function

touch ./function/.config

echo "
TOKEN=${token}
ENDPOINT=${trigger_url}
" > ./function/.config

template="ROSTemplateFormatVersion: '2015-09-01'
Transform: 'Aliyun::Serverless-2018-04-03'
Resources:
  $service_name: # service name
    Type: 'Aliyun::Serverless::Service'
    sendMessage: # function name
      Type: 'Aliyun::Serverless::Function'
      Properties:
        Handler: sendMessage.handler #filename
        Runtime: nodejs8
        CodeUri: './'
        Timeout: 60
      Events:
        httpTrigger: # trigger name
          Type: HTTP # http trigger
          Properties:
              AuthType: ANONYMOUS
              Methods: ['GET', 'POST']
"

echo "$template" > ./function/template.yml

cd function
npm add request
npm add raw-body
npm add dotenv

fun deploy > deploy.log

echo '------------------------------------------------------------------------------------------------------------------------------'
echo "|      endpoint    : $trigger_url"
echo "|      token       : $token"
echo '------------------------------------------------------------------------------------------------------------------------------'

open "https://awesome-fc.github.io/dingtalk-broadcast/?token=${token}&endpoint=${trigger_url}"