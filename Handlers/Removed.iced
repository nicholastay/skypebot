# Removed/Edited message handler
 
removedMsgRegex = /<e_m ts="(.+?)" a="(.+?)" t="(.+?)"\/>/

class exports.Removed
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.raw', @removedHandler
        @SkypeBot.Events.on 'skype.message.detailed', @cacheMessages

    removedHandler: (message) =>
        return if @SkypeBot.Config.removedMsgHandling is false # 'idc if disabled'

        removedTest = removedMsgRegex.exec message.resource.content
        username = message.resource.from.split(':')[2]
        cleanConvoUrl = message.resource.conversationLink.split('/').pop()

        if message.resource.skypeeditedid and removedTest
            console.log "[#{@SkypeBot.Tools.formattedTime()}] Removed/edited message detected (data: #{message.resource.content})"
            if @SkypeBot.MessageCache[cleanConvoUrl][username]
                # The original skype message's id is one more than the one that is supplied when the removed message metadata comes through
                findMessageId = (parseInt(removedTest[1])+1).toString()
                foundMessage = (@SkypeBot.MessageCache[cleanConvoUrl][username].filter((msg) -> return msg.id is findMessageId))[0]
                if not foundMessage # skype is weird sometimes+1 sometimes not??
                    findMessageId = removedTest[1]
                    foundMessage = (@SkypeBot.MessageCache[cleanConvoUrl][username].filter((msg) -> return msg.id is findMessageId))[0]
                if not foundMessage # MAYBE ITS EVEN +2 ????
                    findMessageId = (parseInt(removedTest[1])+2).toString()
                    foundMessage = (@SkypeBot.MessageCache[cleanConvoUrl][username].filter((msg) -> return msg.id is findMessageId))[0]
                return if not foundMessage # yep not found, tried +1, +2 and the id itself
                return if not foundMessage.message # weird undefined stuff sometimes idk
                if foundMessage
                    @SkypeBot.Clients.Skype.sendMessage cleanConvoUrl, "Recovering removed/edited message (from skypeID: #{removedTest[2]}): #{foundMessage.message}"

    cacheMessages: (username, displayName, message, convoUrl, resource) =>
        # Temp disable removed message tracking
        if username is @SkypeBot.Config.skype.username
            if message is '~disableRemovedMessages'
                @SkypeBot.Config.removedMsgHandling = false
                return @SkypeBot.Clients.Skype.sendMessage convoUrl, 'Removed/edited message detection has been disabled.'
            else if message is '~enableRemovedMessages'
                @SkypeBot.Config.removedMsgHandling = true
                return @SkypeBot.Clients.Skype.sendMessage convoUrl, 'Removed/edited message detection has been enabled.'
        
        return if @SkypeBot.Config.removedMsgHandling is false


        return if not message or message.match removedMsgRegex # Dont want these in the cache
        messageId = resource.id.substring(0, resource.id.length-3) # Skype when messages are removed, the ID for some reason excludes the last 3. Maybe they are random we will never know

        if !@SkypeBot.MessageCache[convoUrl]
            @SkypeBot.MessageCache[convoUrl] = {}
        if !@SkypeBot.MessageCache[convoUrl][username]
            @SkypeBot.MessageCache[convoUrl][username] = []

        @SkypeBot.MessageCache[convoUrl][username].push
            id: messageId
            message: message

        if @SkypeBot.MessageCache[convoUrl][username].length > 50
            @SkypeBot.MessageCache[convoUrl][username].shift()