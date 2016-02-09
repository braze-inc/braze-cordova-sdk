var fs = require('fs');
var path = require('path');
var DOMParser = require('xmldom').DOMParser;
var xpath = require('xpath');
var common = require('./common');
var ConfigParser = require('cordova-lib').configparser;

module.exports = {
    modifyAppboyPropertiesFile: function() {
        var pluginConfig = common.getPluginConfig('android');

        var appboyFilePath = this._getAppboyPropertiesPath();

        fs.readFile(appboyFilePath, function(err, data) {
            var doc = new DOMParser().parseFromString(data.toString(), 'text/xml');

                var apiKey = xpath.select1("/resources/string[@name='com_appboy_api_key']", doc).firstChild;
                apiKey.data = pluginConfig.apiKey;
                var pushReg = xpath.select1("/resources/bool[@name='com_appboy_push_gcm_messaging_registration_enabled']", doc).firstChild
                pushReg.data = pluginConfig.pushRegEnabled;
                var senderID = xpath.select1("/resources/string[@name='com_appboy_push_gcm_sender_id']", doc).firstChild
                senderID.data = pluginConfig.senderID;

                fs.writeFileSync(appboyFilePath, doc);
        });

    },

    _getAppboyPropertiesPath: function() {
        return path.join('platforms', 'android', 'res', 'values','appboy.xml');
    },

    _getBroadcastReceiverAppboyPath: function() {
        return path.join('platforms', 'android', 'src', 'com', 'appboy', 'AppboyBroadcastReceiver.java');
    },

    modifyPackageNameOnBroadcastReceiver : function(){

      var filePath = this._getBroadcastReceiverAppboyPath();

      fs.readFile(filePath, 'utf8', function (err,data) {
        if (err) {
          return console.log(err);
        }
        // Get the config.xml to retrieve the 
        var config = new ConfigParser('config.xml');
        var result = data.replace('$PACKAGE_NAME', config.packageName());

        fs.writeFile(filePath, result, 'utf8', function (err) {
           if (err) return console.log(err);
        });
      });

    }

};
