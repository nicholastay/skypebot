Skyweb = require 'skyweb'
entities = require 'entities'

removedMsgRegex = /<e_m ts="(.+?)" a="(.+?)" t="(.+?)"\/>/

class exports.Skype
    constructor: (@SkypeBot) ->

    connect: ->
        skype = @client = @SkypeBot.Clients.Skype = new Skyweb()
        console.log 'Attempting to connect to Skype. This could take a moment...'
        skype.login @SkypeBot.Config.skype.username, @SkypeBot.Config.skype.password
        .then (skypeAccount) ->
            console.log 'Logged in to Skype.'

        skype.messagesCallback = (messages) =>
            for message in messages
                #console.log message
                
                formatTime = @SkypeBot.Tools.formattedTime()
                username = message.resource.from.split(':')[2]
                convoUrl = message.resource.conversationLink
                cleanConvoUrl = message.resource.conversationLink.split('/').pop() # Must use this to reply
                displayName = message.resource.imdisplayname
                msgContent = message.resource.content

                @SkypeBot.Events.emit 'skype.message.raw', message
                if message.resource.content
                    if message.resource.type is 'Message' and not message.resource.content.match removedMsgRegex # Not some removed metadata
                        splitMsg = msgContent.split ' '
                        if message.resource.messagetype is 'Text'
                            # PM
                            console.log "[#{formatTime}] #{displayName}: #{entities.decodeHTML msgContent}"
                            @SkypeBot.Events.emit 'skype.message.pm', username, displayName, entities.decodeHTML(msgContent), cleanConvoUrl
                        else if message.resource.threadtopic and message.resource.messagetype is 'RichText'
                            # GROUP
                            console.log "[#{formatTime}] <GROUP: #{message.resource.threadtopic}> #{displayName}: #{entities.decodeHTML msgContent}"
                            @SkypeBot.Events.emit 'skype.message.group', username, displayName, entities.decodeHTML(msgContent), cleanConvoUrl

                        @SkypeBot.Events.emit 'skype.message', username, displayName, entities.decodeHTML(msgContent), cleanConvoUrl
                        @SkypeBot.Events.emit 'skype.message.detailed', username, displayName, entities.decodeHTML(msgContent), cleanConvoUrl, message.resource # Detailed with all resources for complex modules like removed
                        @SkypeBot.Events.emit 'skype.message.command', username, displayName, splitMsg[0], entities.decodeHTML(splitMsg.slice(1).join(' ')), cleanConvoUrl
