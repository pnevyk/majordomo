path = require 'path'
fs = require 'fs'
exec = require('child_process').exec
mustache = require 'mustache'

debugMode = false

# === Logger ===

log = (name, message) ->
    if message?
        console.log "[\x1b[32mMajordomo\x1b[0m] #{name}: \x1b[34m#{message}\x1b[0m"
    
    else
        console.log "[\x1b[32mMajordomo\x1b[0m] #{name}\x1b[0m"
        
debug = (name, message) ->
    return unless debugMode
    
    if message?
        console.log "[\x1b[33mMajordomo\x1b[0m] #{name}: \x1b[34m#{message}\x1b[0m"
    
    else
        console.log "[\x1b[33mMajordomo\x1b[0m] #{name}\x1b[0m"


###
condition
---------
list -> 'id.choice' or '!id.choice'
checkbox -> 'id:choice' or '!id:choice'
input/password/setter -> 'id=value' or 'id!=value'
confirm -> 'id' or '!id'
has module -> '%module' or '%!module'
###
transformCondition = (condition) ->
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

        
        
# === Executor ===

class Executor
    constructor: ->
        @queue = []
        @locked = false
        
    dequeue: ->
        if @queue.length isnt 0 and not @locked
            @locked = true
            toExecute = @queue.shift()
            log 'execute', toExecute.command
            exec toExecute.command, (error, stdout, stderr) =>
                toExecute.callback(error, stdout, stderr)
                @locked = false
                @dequeue()
        
    execute: (command, cb) ->
        debug 'execute', command
        return cb null, '', '' if debugMode
        @queue.push(
            command: command,
            callback: cb
        )
        @dequeue()


# === FileSystem ===

class FileSystem
    constructor: (@root) ->
    
    exists: (filepath) ->
        filepath = path.join @root, filepath
        debug 'exists', filepath
        return false if debugMode
        fs.existsSync filepath
    
    read: (filepath) ->
        filepath = path.join @root, filepath
        debug 'read', filepath
        return '' if debugMode
        fs.readFileSync(filepath).toString()
        
    write: (filepath, content) ->
        filepath = path.join @root, filepath
        debug 'write', filepath
        return if debugMode
        log 'write', filepath
        fs.writeFileSync filepath, content
        
    remove: (filepath) ->
        filepath = path.join @root, filepath
        debug 'remove', filepath
        return if debugMode
        log 'remove', filepath
        fs.unlinkSync filepath
        
    mkdir: (filepath) ->
        filepath = path.join @root, filepath
        debug 'mkdir', filepath
        return if debugMode
        log 'mkdir', filepath
        fs.mkdirSync filepath
        
    rmdir: (filepath) ->
        filepath = path.join @root, filepath
        debug 'rmdir', filepath
        return if debugMode
        log 'rmdir', filepath
        fs.rmdirSync filepath
        
    
    list: (filepath) ->
        filepath = path.join @root, filepath
        debug 'list', filepath
        return [] if debugMode
        fs.readdirSync filepath
        
    chmod: (filepath, mode) ->
        filepath = path.join @root, filepath
        debug 'chmod', filepath
        return if debugMode
        log 'chmod', filepath
        fs.chmodSync filepath, mode
        
module.exports.template = (template, data) ->
    debug 'template', template
    return if debugMode
    mustache.render template, data
    
module.exports.Executor = Executor
module.exports.FileSystem = FileSystem
    
module.exports.log = log
module.exports.debug = debug

module.exports.setDebugMode = ->
    debugMode = true
    
module.exports.transformCondition = transformCondition