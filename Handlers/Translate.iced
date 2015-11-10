# Translation with some free api because google pls
request = require 'request'

class exports.Translate
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.command', @handleCommand

    handleCommand: (username, displayName, command, cmdArgs, conversationUrl) =>
        if command is '~translate'
            splitArgs = cmdArgs.split ' '

            return if not splitArgs[0] or not splitArgs[1]
            toLang = splitArgs[0]
            toTranslate = splitArgs.slice(1).join(' ')

            await request @SkypeBot.Tools.rfc3986EncodeURI('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' + @SkypeBot.Config.yandex.apikey + '&text=' + toTranslate + '&lang=' + toLang), defer err, resp, body
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'There was an error with the Yandex Translation API.' if err or resp.statusCode isnt 200
            body = JSON.parse body
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'There was an error with the Yandex Translation API.' if body.code isnt 200
            @SkypeBot.Clients.Skype.sendMessage conversationUrl, "#{toTranslate}\n-- #{toLang} (#{body.lang}) -->\n#{decodeURI body.text[0]}"