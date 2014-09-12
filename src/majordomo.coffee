fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
inquirer = require 'inquirer'
mustache = require 'mustache'
_ = require 'lodash'
majorfile = require('./majorfile')()

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
    
    
# = Condition transformer =

###
condition
---------
list -> 'id.choice' or '!id.choice'
checkbox -> 'id:choice' or '!id:choice'
input/password/setter -> 'id=value' or 'id!=value'
confirm -> 'id' or '!id'
has module -> '%module' or '%!module'
###
transformCondition = (condition, branch) ->
    if condition[0] isnt '%'
        if condition[0] isnt '!'
            if condition.indexOf('.') isnt -1
                condition = condition.split '.'
                () ->
                    @get(condition[0]) is condition[1]
                    
            else if condition.indexOf(':') isnt -1
                condition = condition.split ':'
                () ->
                    @get(condition[0]).indexOf(condition[1]) isnt -1
                    
            else if condition.indexOf('!=') isnt -1
                condition = condition.split '!='
                () ->
                    @get(condition[0]) isnt condition[1]
                    
            else if condition.indexOf('=') isnt -1
                condition = condition.split '='
                () ->
                    @get(condition[0]) is condition[1]
                    
            else
                () ->
                    @get condition
        else
            condition = condition.substring 1
            if condition.indexOf('.') isnt -1
                condition = condition.split '.'
                () ->
                    @get(condition[0]) isnt condition[1]
                    
            else if condition.indexOf(':') isnt -1
                condition = condition.split ':'
                () ->
                    @get(condition[0]).indexOf(condition[1]) is -1
                    
            else
                () ->
                    not @get condition 
                    
    else
        if condition[1] isnt '!'
            condition = condition.substring 1
            () ->
                @has condition
                
        else
            condition = condition.substring 2
            () ->
                not @has condition


# = Logger =

log = (command, param) ->
    if param?
        console.log "[\x1b[32mMajordomo\x1b[0m] #{command}: \x1b[34m#{param}\x1b[0m"
    
    else
        console.log "[\x1b[32mMajordomo\x1b[0m] #{command}\x1b[0m"
        
debug = (message) ->
    if debugMode
        console.log "[\x1b[33mMajordomo --debug\x1b[0m] #{message}"
    

# === Executor ===

class Executor
    constructor: ->
        @queue = []
        @locked = false
        
    log: (command) ->
        log 'executes', command
        
    dequeue: ->
        if @queue.length isnt 0 and not @locked
            @locked = true
            toExecute = @queue.shift()
            @log toExecute.command
            exec toExecute.command, (error, stdout, stderr) =>
                toExecute.callback(error, stdout, stderr)
                @locked = false
                @dequeue()
        
    execute: (command, cb) ->
        @queue.push(
            command: command,
            callback: cb
        )
        @dequeue()


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
            condition = transformCondition condition, this
        
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
executor = new Executor()
module.exports.exec = (command, cb = (->)) ->
    if debugMode
        return debug "executing #{command}"

    executor.execute command, cb

# Read
read = (filepath) ->
    fs.readFileSync(path.join path.dirname(module.parent.filename), filepath).toString()

module.exports.read = (filepath) ->
    debug "reading #{filepath}"
    read filepath
    
# Write
module.exports.write = (filepath, content) ->
    filepath = path.join process.cwd(), filepath
    log 'writes', filepath
    fs.writeFileSync filepath, content
    
# Template
module.exports.template = (filepath, data) ->
    debug "templating #{filepath}"
    debug "template data: \n#{data}"
    template = read filepath
    mustache.render template, data    

# Mkdir
module.exports.mkdir = (filepath) ->
    filepath = path.join process.cwd(), filepath
    log 'makes directory', filepath
    fs.mkdirSync filepath
    
# Log
module.exports.log = log

module.exports.debug = debug

module.exports.debugMode = (value) ->
    debugMode = value