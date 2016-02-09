var path = require('path');

module.exports = {
    getPluginConfig: function(platform) {
        var pluginConfig = require(path.join('..', '..', '..', platform + '.json'));

        return {
            apiKey: pluginConfig.installed_plugins['cordova-plugin-appboy'].APPBOY_API_KEY,
            senderID: pluginConfig.installed_plugins['cordova-plugin-appboy'].APPBOY_GCM_SENDER_ID,
            pushRegEnabled: pluginConfig.installed_plugins['cordova-plugin-appboy'].APPBOY_PUSH_REGISTRATION_ENABLED
        };
    }
};
