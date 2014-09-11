module.exports = function (config) {
    var output = '', key, value;
    for (var i = 0, keys = Object.keys(config.modules), len = keys.length; i < len; i++) {
        key = keys[i];
        value = config.modules[key];
        
        output += key + ':' + value + ',';
    }
    
    console.log(output.substr(0, output.length - 1));
};