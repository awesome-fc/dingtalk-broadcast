#!/bin/bash

set -e

endpoint=$(cat ~/.fcli/config.yaml | grep 'endpoint' | awk -F ': ' '{print $2}' | sed '2d')
api_version=$(cat ~/.fcli/config.yaml | grep 'api_version' | awk -F '"' '{print $2}')
service_name="dingRobot"-$(date +%s | base64 | sed 's/=/a/g' | sed 's/&/b/g' |head -c 8 )
token=$(date +%s |base64 | sed 's/=/a/g' | sed 's/&/b/g')
urls=($(cat ./urls.txt | grep 'https' | grep -v '#'))
url=""
trigger_url=$endpoint/$api_version/proxy/$service_name/sendMessage/

for i in ${!urls[@]};
    do 
        if [ $i = 0 ]; 
        then
           url+=\"${urls[$i]}\" 
        else
            url+=,\"${urls[$i]}\"
        fi
done

sendMessage="var request = require('request');
var getRawBody = require('raw-body');
var getFormBody = require('body/form');
var body = require('body');
var urls=[
   $url
];

var textMsg = {
  \"msgtype\": \"text\",
  \"text\": {
      \"content\": \"\"
  },
  \"at\":{
    \"isAtAll\": false
  }
}

var markdownMsg = {
    \"msgtype\": \"markdown\",
    \"markdown\": {
      \"title\":\"函数计算\",
      \"text\":\"\"     
    },
    \"at\": {
      \"isAtAll\": false
    }
 }

module.exports.handler = function(req, resp, context) { 
    var token = \"${token}\"
    var error = {
        message : \"token 错误\"
    }
    var size = urls.length
    getRawBody(req, function(err, body) {
        var str = body.toString()
        console.log(body.toString())
        if (req.queries.token !== token) {
            resp.send(JSON.stringify(error, null, '    '));
        } else {
            console.log(req.queries.isAtAll)
            if (req.queries.isAtAll === \"true\") {
              textMsg.at.isAtAll = true
              markdownMsg.at.isAtAll = true
            }
            console.log(textMsg.at.isAtAll)
            var type = req.queries.type
            textMsg.text.content = str
            markdownMsg.markdown.text = str
            urls.forEach(url => {
                request({
                    url: url,
                    method: \"POST\",
                    json: true,
                    headers: {
                        \"content-type\": \"application/json\",
                    },
                    body: type == 'markdown' ? markdownMsg : textMsg
                }, function(error, response, body) {
                    if(--size <= 0) {
                        resp.send(str);
                    }
                });
            });            
        }
        
    }); 
};
"

rm -rf function

mkdir function

echo "$sendMessage" > ./function/sendMessage.js

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

fun deploy > deploy.log

echo "open \"https://awesome-fc.github.io/dingtalk-broadcast/?token=${token}&endpoint=${trigger_url}\"" > ../start.sh

echo '------------------------------------------------------------------------------------------------------------------------------'
echo "|      endpoint    : $trigger_url"
echo "|      token       : $token"
echo '------------------------------------------------------------------------------------------------------------------------------'

open "https://awesome-fc.github.io/dingtalk-broadcast/?token=${token}&endpoint=${trigger_url}"