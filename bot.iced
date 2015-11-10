Skyweb = require 'skyweb'
Osu = require 'nodesu'
moment = require 'moment-timezone'
request = require 'request'
entities = require 'entities'
repl = require 'repl'

config = require './config'

messageCache = {}

fahrenheitToCelsius = (degrees) -> return (+degrees - 32) * (5 / 9)

# https://stackoverflow.com/questions/18251399/why-doesnt-encodeuricomponent-encode-sinlge-quotes-apostrophes
rfc3986EncodeURI = (str) -> return encodeURI(str).replace(/[!'()*]/g, escape)

# More readability for setTimeout
delay = (ms, func) -> setTimeout func, ms

# https://stackoverflow.com/questions/2532218/pick-random-property-from-a-javascript-object
randomProperty = (obj) ->
    keys = Object.keys obj
    return obj[keys[keys.length * Math.random() << 0]]

# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
getRandomInt = (min, max) -> return Math.floor(Math.random() * (max - min)) + min


r = repl.start 'Skype-Bot> '
r.context.mcache = messageCache
console.log '\n'

skype = new Skyweb()
console.log 'Attempting to connect to Skype. This could take a moment...'
skype.login config.skype.username, config.skype.password
.then (skypeAccount) ->
    console.log 'Logged in to Skype.'

osuApi = new Osu.api
    apiKey: config.osu.apikey

r.context.skype = skype
r.context.osuApi = osuApi

handleMessageText = (user, displayname, message, conversationLink) ->
    return if not user or not message or not conversationLink
    displayname = user if not displayname
    convLink = conversationLink.split('/').pop()
    message = entities.decodeHTML message # Scrub the goddamn skype HTML encoded messages
    splitMessage = message.split ' '
    switch splitMessage[0]
        when '!nickbot' then skype.sendMessage convLink, "Hi #{displayname}! I am the bot behind this account right now. I am currently in development by @nicholastay (github) and I could easily fuck up any time..."
        when '!offline'
            if user isnt config.skype.username
                skype.sendMessage convLink, "#{displayname}, you cannot make me seppuku because you are not the chosen one."
            else
                skype.sendMessage convLink, "I am now going offline on the request of #{displayname}. [Bot offline]"
                delay 2500, -> process.exit()
        when '!osurank'
            username = if splitMessage[1] then splitMessage[1] else 'Nexerq'
            await osuApi.getUser osuApi.user.byUsername(username), defer err, resp
            return skype.sendMessage convLink, 'There was an error with the osu! api. Please try again later.' if err
            skype.sendMessage convLink, """#{resp.username}'s osu! stats: (https://osu.ppy.sh/u/#{resp.user_id})
                                            PP: #{resp.pp_raw}pp, Accuracy: #{parseFloat(resp.accuracy).toFixed(2)}%
                                            Rank: ##{resp.pp_rank} (Global), ##{resp.pp_country_rank} (#{resp.country})
                                            Total score: #{resp.total_score}, Level: #{parseInt(resp.level)}
                                            Playcount: #{resp.playcount} plays"""
        when '!translate'
            return if not splitMessage[1] or not splitMessage[2]
            toLang = splitMessage[1]
            toTranslate = splitMessage
            toTranslate.splice 0, 2
            toTranslate = toTranslate.join ' '

            await request rfc3986EncodeURI('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' + config.yandex.apikey + '&text=' + toTranslate + '&lang=' + toLang), defer err, resp, body
            return skype.sendMessage convLink, 'There was an error with the Yandex Translation API.' if err or resp.statusCode isnt 200
            body = JSON.parse body
            return skype.sendMessage convLink, 'There was an error with the Yandex Translation API.' if body.code isnt 200
            skype.sendMessage convLink, "#{toTranslate}\n-- #{toLang} (#{body.lang}) -->\n#{decodeURI body.text[0]}"
        when '!weather'
            if splitMessage[1]
                location = splitMessage
                location.splice 0, 1
                location = location.join ' '
            else location = 'Melbourne'

            await request 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22' + location + '%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys', defer err, resp, body
            return skype.sendMessage convLink, 'There was an error with the Yahoo! Developer API. Please try again later.' if err or resp.statusCode isnt 200
            body = JSON.parse body
            return skype.sendMessage convLink, "#{displayname}, you have entered an invalid location. Please try again or fuck off if you're not even trying to give a valid place." if not body.query.results
            skype.sendMessage convLink, "#{displayname}! As requested, the current Weather #{body.query.results.channel.item.title} is #{body.query.results.channel.item.condition.text} with a temperature of #{fahrenheitToCelsius(body.query.results.channel.item.condition.temp).toFixed(1)}C. (powered by the Yahoo! Developer API)"

skype.messagesCallback = (messages) ->
    for message in messages
        #console.log message
        
        formatTime = moment(message.resource.originalarrivaltime).format("MM/DD/YYYY hh:mm:ss")
        username = message.resource.from.split(':')[2]
        messageId = message.resource.id.substring(0, message.resource.id.length-3)
        convoUrl = message.resource.conversationLink
        cleanConvoUrl = convoUrl.split('/').pop()
        displayName = message.resource.imdisplayname
        msgContent = message.resource.content
        
        # Check for removed message
        removedMsgRegex = /<e_m ts="(.+?)" a="(.+?)" t="(.+?)"\/>/.exec msgContent

        # General messages
        if message.resource.type is 'Message'
            if message.resource.messagetype is 'Text'
                # PM
                console.log "[#{formatTime}] #{displayName}: #{msgContent}"
            else if message.resource.threadtopic and message.resource.messagetype is 'RichText'
                # GROUP
                console.log "[#{formatTime}] <GROUP: #{message.resource.threadtopic}> #{displayName}: #{msgContent}"


            # Store the message if it's not one of those metadata removed regex things
            if not removedMsgRegex
                if !messageCache[convoUrl]
                    messageCache[convoUrl] = {}
                if !messageCache[convoUrl][username]
                    messageCache[convoUrl][username] = []

                messageCache[convoUrl][username].push
                    id: messageId
                    message: message.resource.content

                if messageCache[convoUrl][username].length > 50
                    messageCache[convoUrl][username].shift()
                handleMessageText username, displayName, msgContent, convoUrl


            # Removed Messages
            if message.resource.skypeeditedid and removedMsgRegex
                console.log "[#{formatTime}] Removed/edited message detected: #{msgContent}"
                if messageCache[convoUrl][username]
                    # The original skype message's id is one more than the one that is supplied when the removed message metadata comes through
                    findMessageId = (parseInt(removedMsgRegex[1])+1).toString()
                    foundMessage = (messageCache[convoUrl][username].filter((msg) -> return msg.id is findMessageId))[0]
                    if not foundMessage # skype is weird sometimes+1 sometimes not??
                        findMessageId = removedMsgRegex[1]
                        foundMessage = (messageCache[convoUrl][username].filter((msg) -> return msg.id is findMessageId))[0]
                    if foundMessage
                        skype.sendMessage cleanConvoUrl, "Recovering removed/edited message (from skypeID: #{removedMsgRegex[2]}): #{foundMessage.message}"