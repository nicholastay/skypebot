repl = require 'repl'
events = require 'events'
fs = require 'fs'
path = require 'path'

class SkypeBotClass
    constructor: ->
        @Config = {}
        @Clients = {}
        @Handlers = {}
        @MessageCache = {}
        @Events = new events.EventEmitter()


SkypeBot = new SkypeBotClass

# Load config
SkypeBot.Config = require './config'

# Load base modules
for mod in fs.readdirSync './Base'
    continue if path.extname mod isnt '.iced'
    modName = mod.replace '.iced', ''
    mod = require "./Base/#{modName}"
    SkypeBot[modName] = new mod[modName] SkypeBot
    console.log "Loaded base module: #{modName}"

# Load handlers
for handler in fs.readdirSync './Handlers'
    continue if path.extname handler isnt '.iced'
    handlerName = handler.replace '.iced', ''
    handler = require "./Handlers/#{handlerName}"
    SkypeBot.Handlers[handlerName] = new handler[handlerName] SkypeBot
    console.log "Loaded chat handler: #{handlerName}"

SkypeBot.Skype.connect()

# Start repl
r = repl.start 'Skype-Bot> '
r.context.mcache = SkypeBot.MessageCache
r.context.SkypeBot = SkypeBot
console.log '\n'