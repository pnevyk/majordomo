/*global describe, it, before, after*/

var path = require('path');
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
        describe('- src', function () {
            it('should operate on files in directory where the script is located', function () {
                expect(majordomo.src.exists('spec.js')).to.be(true);
            });
        });
        
        describe('- dest', function () {
            before(function () {
                try {
                    process.chdir(path.join(__dirname, '..'));
                }
                
                catch (err) {
                    console.log('Cannot change current working directory to test Majorodmo because of this error:', err.message);
                }
            });
            
            it('should operate on files in directory where the script is executed', function () {
                expect(majordomo.dest.exists('majordomo/spec.js')).to.be(true);
            });
        });
    });
});