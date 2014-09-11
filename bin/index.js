#!/usr/bin/env node

var path = require('path');

var majorfile = require('../lib/majorfile')();
var majordomo = require('../lib/majordomo');

var args = process.argv.slice(2);
var modules = {};
var config = {};

var i, len, item, command, toRun;

for (i = 0, len = args.length; i < len; i++) {
    item = args[i];
    
    if (item[0] === '-' || item[0] === '+') {
        modules[item.substring(1)] = item[0];
    }
    
    else {
        command = item;
    }
}

config.modules = modules;

if (majorfile.custom[command]) {
    toRun = require(path.join(process.cwd(), majorfile.custom[command]));
}

else {
    toRun = require('major-' + command);
}

majordomo.log('runs', command);
toRun(config);