var fs = require('fs'), path = require('path');

module.exports = function (context) {

    var platformRoot = path.join(context.opts.projectRoot, 'platforms/ios/cordova/lib');
    var podFile = path.join(platformRoot, 'Podfile.js');

    if (fs.existsSync(podFile)) {

        fs.readFile(podFile, 'utf8', function (err, data) {

            if (err) {
                throw new Error('Unable to find Podfile: ' + err);
            }

            console.log("Changing Podfile.js file")
            data = data.replace("8.0", "9.3");
            data = data.replace(" do\\n", " do\\n\\tuse_modular_headers!\\n");

            fs.writeFile(podFile, data, 'utf8', function (err) {
                if (err) throw new Error('Unable to write into Podfile.js ' + err);
            });
        });
    } else {
        throw new Error("Coudn't find Podfile.js ");
    }

    var buildFile = path.join(platformRoot, 'build.js');
    if (fs.existsSync(buildFile)) {

        fs.readFile(buildFile, 'utf8', function (err, data) {

            if (err) {
                throw new Error('Unable to find buildFile: ' + err);
            }

            console.log("Changing build.js file: " + buildFile)
            data = data.replace("customArgs.configuration_build_dir || `CONFIGURATION_BUILD_DIR=${path.join(projectPath, 'build', 'device')}`", "//customArgs.configuration_build_dir || `CONFIGURATION_BUILD_DIR=${path.join(projectPath, 'build', 'device')}`");
            data = data.replace("customArgs.configuration_build_dir || `CONFIGURATION_BUILD_DIR=${path.join(projectPath, 'build', 'emulator')}`", "//customArgs.configuration_build_dir || `CONFIGURATION_BUILD_DIR=${path.join(projectPath, 'build', 'emulator')}`");

            fs.writeFile(buildFile, data, 'utf8', function (err) {
                if (err) throw new Error('Unable to write into build.js ' + err);
            });
        });
    } else {
        throw new Error("Coudn't find buildFile.js ");
    }

}