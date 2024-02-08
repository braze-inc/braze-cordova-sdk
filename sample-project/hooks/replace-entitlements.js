var xcode = require('xcode'),
    fs = require('fs'),
    path = require('path');

module.exports = function(context) {
    var projectRoot = context.opts.projectRoot;
    var xcconfigPath = path.join(projectRoot, 'platforms', 'ios', 'cordova', 'build.xcconfig');
    var xcconfigContents = fs.readFileSync(xcconfigPath, 'utf-8');

    var entitlementsLine = 'CODE_SIGN_ENTITLEMENTS = $(PROJECT_DIR)/$(PROJECT_NAME)/Resources/HelloCordova-$(CONFIGURATION).entitlements';
    var regex = /^CODE_SIGN_ENTITLEMENTS = .*/m;

    if (xcconfigContents.match(regex)) {
        // If the line exists, replace it.
        xcconfigContents = xcconfigContents.replace(regex, entitlementsLine);
    } else {
        // If the line doesn't exist, add it.
        xcconfigContents += '\n' + entitlementsLine;
    }

    fs.writeFileSync(xcconfigPath, xcconfigContents, 'utf-8');
};