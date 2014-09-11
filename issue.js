var majordomo = require('majordomo');

module.exports = function () {
    majordomo('issue')
    .ask('input', 'foo', 'Foo')
    .branch('foo=', function () {
        this.ask('input', 'bar', 'Bar')
            .branch('bar=', function () {
                this.ask('input', 'baz', 'Baz');
            });
    })
    .ask('input', 'qux', 'Qux')
    .run(function () {
        //
    });
};