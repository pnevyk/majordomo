# Majordomo

Majordomo is a command line utility which provides a set of [commands](#commands_list) which help you to do common things in a comfortable way (user friendly prompts, one majorodomo command results in multiple other commands, ...). Just type `majordomo <command>`, maybe answer some questions, and see the result.

The power of Majordomo is in modules. You can specify what parts of command you want to use. For example if you are writing just npm package, you don't want to publish it to bower registry.

### Work in progress

Majordomo is in early development now. It works somehow but it can behave unexpectly and API may change.

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
__terminal:__

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

<a name="commands_list"></a>
## Commands

#### [init](https://github.com/nevyk/major-init)

Majordomo command for initialization of a project.

#### [commit](https://github.com/nevyk/major-commit)

Majordomo command for git commiting in a more comfortable way.

#### [release](https://github.com/nevyk/major-release)

Majordomo command to help to release new version of your project.

### Writing a command

Always name your npm packages as `major-<your-command>`. Tell me if you have written a command and you want to add the command link here.

First, initiate command using `majordomo` function. You have to pass name of the command and configuration which is sent from `majordomo` command line utility.

```js
var majordomo = require('majordomo');

module.exports = function (config) {
    majordomo('name', config);
}
```

Then use [Command API](#command_api) for asking some questions.

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
    - `'property.value'`/`'!property.value'` -> `this.get(property) === value`/`this.get(property) !== value`
    - `'property:value'`/`'!property:value'` -> `this.get(property).indexOf(value) !== -1`/`this.get(property).indexOf(value) === -1`
    - `'property=value'`/`'property!=value'` -> `this.get(property) === value`/`this.get(property) !== value`
    - `'property'`/`'!property'` - checks if property is present
    - `'%module'`/`'%!module'` - checks whether user want to run commands related to specified module
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

It embraces Node `child_process.exec` but gives you possibility to execute commands in a pseudo-synchronous way. It means that `majorodomo.exec` doesn't execute command until previous is finished.

```js
majorodomo.exec('git tag -a v1.0.0', function (error, output) {
    if (!error) console.log(output);
});

//this command isn't executed until previous has finished
majordomo.exec('npm publish ./');
```

##### template(template, data)

Renders a [mustache](http://mustache.github.io/) template.

##### log(name, [message])

Logs a message in Majordomo look.

##### debug(name, [message])

Logs a message in Majorodmo "debug" look. If debug mode is disabled (default), it does nothing.

##### setDebugMode()

Enables debug mode.

##### src

Instance of [FileSystem](#filesystem_api) which root directory is where your command is located (your package).

##### dest

Instance of [FileSystem](#filesystem_api) which root directory is user's working directory.

<a name="filesystem_api"></a>
#### FileSystem API

##### exists(path)

Returns if file/directory exists.

##### read(path)

Returns the content of file.

##### write(path, content)

Writes content to specified file.

##### remove(path)

Removes specified file.

##### mkdir(path)

Makes directory.

##### rmdir(path)

Removes directory.

##### list(path)

Returns array of files in specified directory.

##### chmod(path, mode)

Changes mode of specified file.

## Todo

- Improve documentation
- Fix issues
- Come up with a solution how to test Majorodomo prompts
- Add more tests
- Add asynchronous operations support

## Thank you

- [Inquirer.js](https://github.com/SBoudrias/Inquirer.js) for awesome CLI prompts which Majorodomo just embraces
- [Lo-dash](http://lodash.com/) for useful utility belt
- [Mustache.js](https://github.com/janl/mustache.js/) for nice implementation of Mustache templates
- [Mocha](http://visionmedia.github.io/mocha/) and [expect.js](https://github.com/LearnBoost/expect.js) because I really enjoy writing tests with them
- [Coffeescript](http://coffeescript.org/) because writing JavaScript is fast and beautiful with it

## License

Majordomo is MIT licensed. Feel free to use it, contribute or spread the word. Created with love by Petr Nevyhoštěný ([Twitter](https://twitter.com/pnevyk)).