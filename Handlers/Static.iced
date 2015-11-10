# Just some static commands that always output the same stuff i guess

class exports.Static
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.command', @handleCommand

    handleCommand: (username, displayName, command, cmdArgs, conversationUrl) =>
        switch command
            when '!offline'
                if username isnt @SkypeBot.Config.skype.username
                    @SkypeBot.Clients.Skype.sendMessage conversationUrl, "#{displayName}, you cannot make me seppuku because you are not the chosen one."
                else
                    @SkypeBot.Clients.Skype.sendMessage conversationUrl, "I am now going offline on the request of #{displayName}. [Bot offline]"
                    @SkypeBot.Tools.delay 2500, -> process.exit()

            when '!yandere'
                # just ignore this thanks
                @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'serena'

            when '!nickbot'
                @SkypeBot.Clients.Skype.sendMessage conversationUrl, "Hi #{displayName}! I am the bot behind this account right now. I am currently in development by @nicholastay (github) and I could easily fuck up any time..."