/*global describe, it*/

try {
    process.chdir(__dirname);
}

catch (err) {
    throw new Error('Cannot change working directory to test majorfile module because of this error: ', err.message);
}

var majorfile = require('../../lib/majorfile')();
var expect = require('expect.js');

describe('Majorfile', function () {
    it('should read .majorfile as javascript object', function () {
        expect(majorfile).to.have.keys('custom', 'test');
        expect(majorfile.custom).to.eql({ command: 'command' });
        expect(majorfile.test).to.be('test');
    });
    
    it('should fill in default values into needed properties', function () {
        expect(majorfile).to.have.keys('custom', 'commands', 'modules');
        expect(majorfile.commands).to.be.empty();
        expect(majorfile.modules).to.be.empty();
    });
});