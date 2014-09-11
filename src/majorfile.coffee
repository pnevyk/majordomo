# It reads .majorfile in working directory
# NOTE: maybe it should try load .majorfile from directories above
#       if it's not found in working directory

fs = require 'fs'

readJSON = (path) ->
    JSON.parse fs.readFileSync path

module.exports = () ->
    try
        majorfile = readJSON process.cwd() + '/.majorfile'
        
    catch err
        majorfile = {}
        
    finally
        majorfile.custom = {} unless majorfile.custom
        majorfile.commands = {} unless majorfile.commands
        majorfile.modules = [] unless majorfile.modules
        
    majorfile