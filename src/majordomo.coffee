fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
inquirer = require 'inquirer'
_ = require 'lodash'
majorfile = require('./majorfile')()
util = require './util'

debugMode = false

# === Helpers ===

# = Inquirer objects =

list = (id, question, choices, def) ->
    result =
        type : 'list',
        name : id,
        message : question,
        choices : choices
    
    result['default'] = def if def?
    result
    
checkbox = (id, question, choices, def) ->
    result =
        type : 'checkbox',
        name : id,
        message : question,
        choices : choices
    
    result['default'] = def if def?
    result
    
confirm = (id, question, def) ->
    result =
        type : 'confirm',
        name : id,
        message : question
        
    result['default'] = def if def?
    result
    
input = (id, question, def) ->
    result =
        type : 'input',
        name : id,
        message : question,
    
    result['default'] = def if def?
    result
    
password = (id, question, def) ->
    result =
        type : 'password',
        name : id,
        message : question,
    
    result['default'] = def if def?
    result
    

# === Branch ===

class Branch
    constructor: (@pipeline, @condition, @toInvoke) ->
        @data = {}
        @questions = []
        @shouldReinit = false
    
    _reinit: ->
        if @shouldReinit
            branch = new Branch @pipeline, (() -> true), (->)
            @pipeline.branches.push branch
            @shouldReinit = false
            return branch
            
        this
            
    
    ###
    list -> id (string), question (string), choices (array), [default (number)]
    checkbox -> id (string), question (string), choices (array), default (array)
    confirm -> id (string), question (string), [default (boolean)]
    input -> id (string), question (string), [default (string)]
    password -> id (string), question (string), [default (string)]
    ###
    ask: (type, id, question, other...) ->
        branch = @_reinit()
        obj = switch type
            when 'list' then list id, question, other[0], other[1]
            when 'checkbox' then checkbox id, question, other[0], other[1]
            when 'confirm' then confirm id, question, other[0]
            when 'input' then input id, question, other[0]
            when 'password' then password id, question, other[0]
            
        branch.questions.push obj
        branch
        
    get: (prop) ->
        @pipeline.data[prop]
        
    set: (prop, value) ->
        branch = @_reinit()
        branch.data[prop] = value
        branch
        
    has: (module) ->
        @pipeline.modules.indexOf(module) isnt -1
        
    branch: (condition, branch) ->
        if typeof condition is 'string'
            #transform condition
            condition = util.transformCondition condition, this
        
        _condition = @condition
        inherited = () ->
            _condition.call(this) and condition.call this
        
        
        inherited = inherited.bind this
        @pipeline.branches.push new Branch @pipeline, inherited, branch
        @shouldReinit = true
        this
        
    run: (runner) ->
        @pipeline.run runner
        
    _prompt: (cb) ->
        self = this
        if @questions.length isnt 0
            inquirer.prompt @questions.shift(), (answers) ->
                _.assign self.data, answers
                self._prompt cb
                    
        else
            cb @data
            
            
            
# === Runner ===

class Runner
    constructor: (@data, @modules) ->
    
    get: (prop) ->
        if prop? then @data[prop] else @data
        
    has: (module) ->
        @modules.indexOf(module) isnt -1
        

# === Pipeline ===

class Pipeline
    constructor: (@modules) ->
        @data = {}
        @branches = []
        
    init: ->
        branch = new Branch this, (() -> true), (->)
        @branches.push branch
        branch
        
    dequeue: (cb) ->
        self = this
        if @branches.length isnt 0
            branch = @branches.shift()
            if branch.condition()
                branch.toInvoke()
                branch._prompt (data) ->
                    _.assign self.data, data
                    self.dequeue cb
            
            else
                self.dequeue cb
                    
        else
            cb()
        
    run: (runner) ->
        @dequeue () =>
            runner.call new Runner @data, @modules

# Majordomo
module.exports = (name, config = { modules : [] }) ->
    modules = majorfile.commands[name] or majorfile.modules
    
    for module, change of config.modules
        if change is '-'
            _.remove modules, (m) ->
                m is module
        
        modules.push module if change is '+' and modules.indexOf(module) is -1
    
    pipeline = new Pipeline(modules)
    pipeline.init()

# Exec
executor = new util.Executor()
module.exports.exec = (command, cb = (->)) ->
    executor.execute command, cb
    
src = null
Object.defineProperty module.exports, 'src', (
    get : () ->
        return src if src
        src = (() ->
            # This is very tricky and probably bad solution
            # NOTE: Is there any other possibility how to manage that?
            if module.parent.children[2]
                filename = module.parent.children[2].filename
            else
                filename = module.parent.filename
        
            new util.FileSystem path.dirname filename
        )()
    )

dest = null
Object.defineProperty module.exports, 'dest', (
    get : () ->
        return dest if dest
        dest = new util.FileSystem process.cwd()
    )

module.exports.template = util.template

module.exports.log = util.log
module.exports.debug = util.debug
module.exports.setDebugMode = util.setDebugMode