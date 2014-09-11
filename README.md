# Majordomo

Are you tired of typing a lot of commands if you want to just push repo to GitHub and publish package to npm registry? Or you can't remember those options of command line tools? Majordomo and its [commands](#commands) are solution of your problem. It embraces a few of tools you use into powerful commands. Just type `majordomo <command>`, maybe answer some questions, and see the result.

The power of Majordomo is in modules. You can specify what parts of command you want to use. For example you are writing npm package so you don't want to publish it to bower registry.

### Work in progress

Majordomo is in early development now. It works but it can behave unexpectly and API may change.

## Installation

```bash
$ npm install -g majordomo
```

## Usage

```bash
$ majordomo <command> [+moduleToUse...] [-moduleNotToUse...]
```

### Example

__.majorfile:__

```json
{
    "commands": {
        "foo": ["bar", "baz"]
    }
}
```

```bash
$ majordomo foo +qux -baz
```

With these settings it will run `foo` command with modules `bar` and `qux`.

## Majorfile

In `.majorfile` you configure the behaviour of Majordomo.

### Properties

#### custom

If you have a custom command (it means not installed via npm), you have to specify path to it.

```json
{
    "custom": {
        "foo": "path/to/my/commands/foo"
    }
}
```

It has to be a javascript file but you needn't to write the extension because the file is loaded via `require()`.

#### modules

In this property you specify default modules to use. It can be overwritten either by `commands` property or `majorodomo` command line argument.

```json
{
    "modules": ["foo", "bar"]
}
```

#### commands

Overwrites default modules for individual commands.

```json
{
    "commands": {
        "foo": ["bar", "baz"]
    }
}
```

<a name="commands"></a>
## Commands

### Writing a command

Always name your npm packages as `major-<your-command>`. Tell us if you have written a command and you want to add the command link here.

First, initiate command using `majordomo` function. You have to pass name of the command and configuration which is sent from `majordomo` command line utility.

```js
var majordomo = require('majordomo');

module.exports = function (config) {
    majordomo('name', config);
}
```

Then use [Command API](#command_api) API for asking some questions.

```js
majordomo('name', config).
ask('input', 'name', 'What is your name?').
ask('list', 'gender', 'What is your gender?', ['Male', 'Female']).
ask('confirm', 'confirmation', 'Can we use your personal data?');
```

You can branch questions out based on answers which were given before.

```js
majordomo('name', config).
ask('input', 'name', 'What is your name?').
ask('list', 'gender', 'What is your gender?', ['Male', 'Female']).
branch('gender.Male', function () {
    this.ask('input', 'football', 'What is your favorite football team?');
}).
branch('gender.Female', function () {
    this.ask('input', 'shampoo', 'What is your favorite brand of shampoo?');
}).
ask('confirm', 'confirmation', 'Can we use your personal data?');
```

And at the end, just do what you want.

```js
majordomo('name', connfig).
ask('input', 'name', 'What is your name?').
run(function () {
    console.log('Hi ' + this.get('name') + '!');
});
```

<a name="command_api"></a>
#### Command API

##### ask(type, id, question, choices|[default], [default])

- __type__ - It specifies how user will be prompted. Value can be either `input`, `list`, `checkbox`, `password` or `confirm`.
- __id__ - You access the answer by id.
- __question__ - Message for user.
- __choices__ - If type is either `list` or `checkbox`, the third parameter is array of choices.
- __default__ - The third or fourth parameter is the default value. For `input` and `password` it is string. For `list` it is number (index in choices array). For `checkbox` it is array. And for `confirm it is boolean.

##### branch(condition, branch)

- __condition__ - It can be either function or string. Function must return boolean value whether branch will be executed or not. Use `this.get(property)` and `this.has(module)` for your decisions. You can use majordomo shortcuts for condition by passing a string with a specified format.
    - `'property.value'`/`'!property.value'` - transforms to function which returns `property === value`/`property !== value`
    - `'property:value'`/`'!property:value'` - transforms to function which returns `property.indexOf(value) !== -1`/`property.indexOf(value) === -1`
    - `'property=value'`/`'property!=value'` - transforms to function which returns `property === value`/`property !== value`
    - `'property'`/`'!property'` - checks if property is present
    - `'%module'`/`'%!module'` - checks whether command has module or not
- __branch__ - Function which will be executed if condition is truthy. Command API is binded to `this`.

##### run(action)

- __action__ - Function which will be called after all questions are answered. You can get answers using `this.get(id)` or check if module is present using `this.has(module)`.

##### set(property, value)

- __property__ - Property name which will be set.
- __value__ - Value of manually set property.

##### get(property)

- __property__ - Property name.

##### has(module)

- __module__ - Module name.

Returns if specified module is wanted or not.

#### Majordomo API

Majordomo object provides you some useful functions which you can use in your commands.

##### exec(command, [cb])

It embraces Node `child_process.exec` but gives you possibility to execute commands in a synchronous way. It means that `majorodomo.exec` doesn't execute command until previous is finished.

```js
majorodomo.exec('git tag -a v1.0.0', function (error, output) {
    if (!error) console.log(output);
});

//this command isn't executed until previous is finished
majordomo.exec('npm publish ./');
```

##### read(path)

It reads a file at specified path synchronously relative to command directory.

##### write(path, content)

It writes to a file at specified path synchronously relative to current working directory (where majordomo was executed).

##### mkdir(path)

It makes a directory at specified path synchronously relative to current working directory (where majordomo was executed).

##### template(path, data)

It renders a [mustache](http://mustache.github.io/) template (path is relative to command directory).

##### log(action, [param])

It logs a message in Majordomo look.

## Todo

- Improve documentation
- Fix issues
- Come up with a solution how to test Majorodomo prompts
- Add more tests
- Add asynchronous operations support

## Thank you to

- [Inquirer.js](https://github.com/SBoudrias/Inquirer.js) for awesome CLI prompts which Majorodomo just embraces
- [Lo-dash](http://lodash.com/) for useful utility belt
- [Mustache.js](https://github.com/janl/mustache.js/) for nice implementation of Mustache templates
- [Mocha](http://visionmedia.github.io/mocha/) and [expect.js](https://github.com/LearnBoost/expect.js) because I really enjoy writing tests with them
- [Coffeescript](http://coffeescript.org/) because writing JavaScript is fast and beautiful with it

## License

Majordomo is MIT licensed. Feel free to use it, contribute or spread the word. Created with love by Petr Nevyhoštěný ([Twitter](https://twitter.com/pnevyk)).