/*global describe, it*/

var path = require('path');
var exec = require('child_process').exec;
var majordomo = path.join(__dirname, '../../bin/index.js');
var expect = require('expect.js');

describe('CLI', function () {
    describe('- executing command', function () {
        it('should execute passed command', function () {
            exec(majordomo + ' run', function (error, output) {
                expect(error).to.be(null);
                expect(output).to.contain('majordomo spec status: OK');
            });
        });
        
        it('should require major-* version if no custom command with the same name in .majorfile exists', function () {
            exec(majordomo + ' non-existent', function (error) {
                expect(error).not.to.be(null);
                expect(error).to.contain('Error: Cannot find module \'major-non-existent\'');
            });
        });
    });
    
    describe('- pass given modules changes as config object', function () {
        it('should transfer command line options into configuration object', function () {
            exec(majordomo + ' custom +qux -baz -owl +rat', function (error, output) {
                expect(error).to.be(null);
                expect(output).to.contain('qux:+,baz:-,owl:-,rat:+');
            });
        });
    });
});