# Removed/Edited message handler
 
removedMsgRegex = /<e_m ts="(.+?)" a="(.+?)" t="(.+?)"\/>/

class exports.Removed
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.raw', @removedHandler
        @SkypeBot.Events.on 'skype.message.detailed', @cacheMessages

    removedHandler: (message) =>
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
                return if not foundMessage # yep not found, tried +1 and the id itself
                return if not foundMessage.message # weird undefined stuff sometimes idk
                if foundMessage
                    @SkypeBot.Clients.Skype.sendMessage cleanConvoUrl, "Recovering removed/edited message (from skypeID: #{removedTest[2]}): #{foundMessage.message}"

    cacheMessages: (username, displayName, message, convoUrl, resource) =>
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