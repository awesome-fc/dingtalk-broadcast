var request = require('request');
var getRawBody = require('raw-body');
const fs = require('fs');
require('dotenv').config({ path: './.config' });

var textMsg = {
  "msgtype": "text",
  "text": {
      "content": ""
  },
  "at":{
    "isAtAll": false
  }
}

var markdownMsg = {
    "msgtype": "markdown",
    "markdown": {
      "title":"函数计算",
      "text":""     
    },
    "at": {
      "isAtAll": false
    }
 }

module.exports.handler = function(req, resp, context) { 
    var token = process.env.TOKEN;
    var error = {
        message : "token 错误"
    }
    var data = fs.readFileSync('urls.txt').toString();
    var arr = data.split("\n")
    var urls = new Array()

    for (var i = 0; i < arr.length; i++) {
        if (arr[i] !== '' && arr[i].indexOf('#') === -1 && arr[i].indexOf('http') !== -1) {
            urls.push(arr[i])
        }
    }

    var size = urls.length
    console.log(urls)

    getRawBody(req, function(err, body) {
        var str = body.toString()
        if (req.queries.token !== token) {
            resp.send(JSON.stringify(error, null, '    '));
        } else {
            if (req.queries.isAtAll === "true") {
              textMsg.at.isAtAll = true
              markdownMsg.at.isAtAll = true
            }
            var type = req.queries.type
            textMsg.text.content = str
            markdownMsg.markdown.text = str
            urls.forEach(url => {
                request({
                    url: url,
                    method: "POST",
                    json: true,
                    headers: {
                        "content-type": "application/json",
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

