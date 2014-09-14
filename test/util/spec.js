/*global describe, it, before, after*/

var path = require('path');
var fs = require('fs');
var util = require(path.join(__dirname, '../../lib/util.js'));
var expect = require('expect.js');

var fileSystem;

describe('Util', function () {
    describe('=== FileSystem ===', function () {
        before(function () {
            fileSystem = new util.FileSystem(__dirname);
        });
        
        describe('- read', function () {
            it('should read content of a file relative to current working directory', function () {
                expect(fileSystem.read('template.json')).to.be('{\n    "{{property}}": "{{value}}"\n}');
            });
        });
        
        describe('- write', function () {
            it('should write a file relative to current working directory', function () {
                fileSystem.write('foo.txt', 'Hello world!');
                
                expect(fs.existsSync(__dirname + '/foo.txt')).to.be(true);
                expect(fs.readFileSync(__dirname + '/foo.txt').toString()).to.be('Hello world!');
            });
            
            after(function () {
                fs.unlinkSync(__dirname + '/foo.txt');
            });
        });
        
        describe('- mkdir', function () {
            it('should make a directory relative to current working directory', function () {
                fileSystem.mkdir('bar');
                expect(fs.existsSync(__dirname + '/bar')).to.be(true);
            });
            
            after(function () {
                fs.rmdirSync(__dirname + '/bar');
            });
        });
        
        describe('- template', function () {
            it('should render template with given data', function () {
                var data = {
                    property: 'foo',
                    value: 'bar'
                };
                
                expect(util.template(fs.readFileSync(__dirname + '/template.json').toString(), data)).to.be('{\n    "foo": "bar"\n}');
            });
        });
    })
})