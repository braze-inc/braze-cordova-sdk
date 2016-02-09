var android = require('./lib/android');
var ios = require('./lib/ios');

module.exports = function(context) {
    var platforms = context.opts.cordova.platforms;

    // Modify the appboyPremodify the appboy.xml
    if (platforms.indexOf('android') !== -1) {
        android.modifyAppboyPropertiesFile();
        android.modifyPackageNameOnBroadcastReceiver();
    }

};
