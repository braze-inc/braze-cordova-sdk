var android = require('./lib/android');

module.exports = function(context) {
    var platforms = context.opts.cordova.platforms;

    // Modify the appboyPremodify the appboy.xml
    if (platforms.indexOf('android') !== -1) {
        android.modifyAppboyPropertiesFile();
        android.modifyPackageNameOnBroadcastReceiver();
    }

};
