/*global describe, it, before, after*/

var path = require('path');
var fs = require('fs');
var majordomo = require(path.join(__dirname, '../../lib/majordomo.js'));
var expect = require('expect.js');

describe('Majordomo', function () {
    describe('=== Command API ===', function () {
        describe('- setter and getter', function () {
            it('should save a value which can be retrieved later', function () {
                majordomo('spec')
                .set('property', 'value')
                .run(function () {
                    expect(this.get('property')).to.be('value');
                });
            });
            
            it('should propagate properties to branches', function () {
                var property;
                
                majordomo('spec')
                .set('property', 'value')
                .branch(function () { return true; }, function () {
                    property = this.get('property');
                })
                .run(function () {
                    expect(property).to.be('value');
                });
            });
        });
        
        describe('- branches', function () {
            it('should have access to properties in condition function', function () {
                var property;
                
                majordomo('spec')
                .set('property', 'value')
                .branch(function () {
                    property = this.get('property');
                    return false;
                })
                .run(function () {
                    expect(property).to.be('value');
                });
            });
            
            it('should have access to properties in condition function', function () {
                var ok = false;
                
                majordomo('spec', { modules : { foo : '+' } })
                .branch(function () {
                    ok = this.has('foo');
                    return false;
                })
                .run(function () {
                    expect(ok).to.be(true);
                });
            });
            
            it('should be called only if condition is succeded', function () {
                var should = false;
                var shouldnt = false;
                
                majordomo('spec')
                .branch(function () { return true; }, function () {
                    should = true;
                })
                .branch(function () { return false; }, function () {
                    shouldnt = true;
                })
                .run(function () {
                    expect(should).to.be(true);
                    expect(shouldnt).to.be(false);
                });
            });
        });
        
        describe('- transforming condition', function() {
            it('should check if given property is (not) equal to specified value using dot syntax', function () {
                var positive = false;
                var negative = false;
                var persistent = false;
                
                majordomo('spec')
                .set('property', 'value')
                .branch('property.value', function () {
                    positive = true;
                })
                .branch('!property.wrong', function () {
                    negative = true;
                })
                .branch('!property.value', function () {
                    persistent = true;
                })
                .branch('property.wrong', function () {
                    persistent = true;
                })
                .run(function () {
                    expect(positive).to.be(true);
                    expect(negative).to.be(true);
                    expect(persistent).to.be(false);
                });
            });
            
            it('should check if given property does (not) contain specified value using colon syntax', function () {
                var positive = false;
                var negative = false;
                var persistent = false;
                
                majordomo('spec')
                .set('property', ['value'])
                .branch('property:value', function () {
                    positive = true;
                })
                .branch('!property:wrong', function () {
                    negative = true;
                })
                .branch('!property:value', function () {
                    persistent = true;
                })
                .branch('property:wrong', function () {
                    persistent = true;
                })
                .run(function () {
                    expect(positive).to.be(true);
                    expect(negative).to.be(true);
                    expect(persistent).to.be(false);
                });
            });
            
            it('should check if given property is (not) equal to specified value using equal symbol', function () {
                var positive = false;
                var negative = false;
                var persistent = false;
                
                majordomo('spec')
                .set('property', 'value')
                .branch('property=value', function () {
                    positive = true;
                })
                .branch('property!=wrong', function () {
                    negative = true;
                })
                .branch('property!=value', function () {
                    persistent = true;
                })
                .branch('property=wrong', function () {
                    persistent = true;
                })
                .run(function () {
                    expect(positive).to.be(true);
                    expect(negative).to.be(true);
                    expect(persistent).to.be(false);
                });
            });
            
            it('should check if given property is (not) truthy', function () {
                var positive = false;
                var negative = false;
                var persistent = false;
                
                majordomo('spec')
                .set('property', true)
                .branch('property', function () {
                    positive = true;
                })
                .branch('!wrong', function () {
                    negative = true;
                })
                .branch('!property', function () {
                    persistent = true;
                })
                .branch('wrong', function () {
                    persistent = true;
                })
                .run(function () {
                    expect(positive).to.be(true);
                    expect(negative).to.be(true);
                    expect(persistent).to.be(false);
                });
            });
            
            it('should check of module is (not) used', function() {
                var positive = false;
                var negative = false;
                var persistent = false;
                
                majordomo('spec', { modules : { foo : '+' } })
                .branch('%foo', function () {
                    positive = true;
                })
                .branch('%!bar', function () {
                    negative = true;
                })
                .branch('%!foo', function () {
                    persistent = true;
                })
                .branch('%bar', function () {
                    persistent = true;
                })
                .run(function () {
                    expect(positive).to.be(true);
                    expect(negative).to.be(true);
                    expect(persistent).to.be(false);
                });
            });
        });
    });
    
    describe('=== Majordomo API ===', function () {
        describe('- executing command', function () {
            //
        });
        
        describe('- writing file', function () {
            before(function () {
                try {
                    process.chdir(__dirname);
                }
                
                catch (err) {
                    throw new Error('Cannot change working directory to test majordomo.write because of this error: ', err.message);
                }
            });
            
            it('should write a file relative to current working directory', function () {
                majordomo.write('foo.txt', 'Hello world!');
                
                expect(fs.existsSync(__dirname + '/foo.txt')).to.be(true);
                expect(fs.readFileSync(__dirname + '/foo.txt').toString()).to.be('Hello world!');
            });
            
            after(function () {
                fs.unlinkSync(__dirname + '/foo.txt');
            });
        });
        
        describe('- making directory', function () {
            before(function () {
                try {
                    process.chdir(__dirname);
                }
                
                catch (err) {
                    throw new Error('Cannot change working directory to test majordomo.write because of this error: ', err.message);
                }
            });
            
            it('should make a directory relative to current working directory', function () {
                majordomo.mkdir('bar');
                
                expect(fs.existsSync(__dirname + '/bar')).to.be(true);
            });
            
            after(function () {
                fs.rmdirSync(__dirname + '/bar');
            });
        });
        
        describe('- reading file', function () {
            it('should read content of a file relative to current working directory', function () {
                expect(majordomo.read('template.json')).to.be('{\n    "{{property}}": "{{value}}"\n}');
            });
        });
        
        describe('- templates', function () {
            it('should render template with given data', function () {
                var data = {
                    property: 'foo',
                    value: 'bar'
                };
                
                expect(majordomo.template('template.json', data)).to.be('{\n    "foo": "bar"\n}');
            });
        });
    });
});