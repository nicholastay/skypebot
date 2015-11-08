Skyweb = require 'skyweb'
Osu = require 'nodesu'
moment = require 'moment-timezone'
request = require 'request'
entities = require 'entities'
repl = require 'repl'

config = require './config'

fahrenheitToCelsius = (degrees) -> return (+degrees - 32) * (5 / 9)

# https://stackoverflow.com/questions/18251399/why-doesnt-encodeuricomponent-encode-sinlge-quotes-apostrophes
rfc3986EncodeURI = (str) -> return encodeURI(str).replace(/[!'()*]/g, escape)

r = repl.start 'Skype-Bot> '
r.context.skype = skype
r.context.osuApi = osuApi
console.log '\n'

skype = new Skyweb()
console.log 'Attempting to connect to Skype. This could take a moment...'
skype.login config.skype.username, config.skype.password
.then (skypeAccount) ->
    console.log 'Logged in to Skype.'

osuApi = new Osu.api
    apiKey: config.osu.apikey

handleMessageText = (user, message, conversationLink) ->
    return if not user or not message or not conversationLink
    convLink = conversationLink.split('/').pop()
    message = entities.decodeHTML message # Scrub the goddamn skype HTML encoded messages
    splitMessage = message.split ' '
    switch splitMessage[0]
        when '!nickbot' then skype.sendMessage convLink, "Hi #{user}! I am the bot behind Nicholas Tay's account right now. I am currently in development and I could easily fuck up any time..."
        when '!osurank'
            username = if splitMessage[1] then splitMessage[1] else 'Nexerq'
            await osuApi.getUser osuApi.user.byUsername(username), defer err, resp
            return skype.sendMessage convLink, 'There was an error with the osu! api. Please try again later.' if err
            skype.sendMessage convLink, """#{resp.username}'s osu! stats: (https://osu.ppy.sh/u/#{resp.user_id})
                                            PP: #{resp.pp_raw}pp, Accuracy: #{parseInt(resp.accuracy).toFixed(2)}%
                                            Rank: ##{resp.pp_rank} (Global), ##{resp.pp_country_rank} (#{resp.country})
                                            Total score: #{resp.total_score}, Level: #{parseInt(resp.level).toFixed(0)}
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
            return skype.sendMessage convLink, "#{user}, you have entered an invalid location. Please try again or fuck off if you're not even trying to give a valid place." if not body.query.results
            skype.sendMessage convLink, "#{user}! As requested, the current Weather #{body.query.results.channel.item.title} is #{body.query.results.channel.item.condition.text} with a temperature of #{fahrenheitToCelsius(body.query.results.channel.item.condition.temp).toFixed(1)}C. (powered by the Yahoo! Developer API)"

skype.messagesCallback = (messages) ->
    for message in messages
        #console.log message
        
        # Private Messages
        if message.resource.type is 'Message' and message.resource.messagetype is 'Text'
            console.log "[#{moment(message.resource.originalarrivaltime).format("MM/DD/YYYY hh:mm:ss")}] #{message.resource.imdisplayname}: #{message.resource.content}"
            handleMessageText message.resource.imdisplayname, message.resource.content, message.resource.conversationLink

        else if message.resource.type is 'Message' and message.resource.threadtopic and message.resource.messagetype is 'RichText'
            console.log "[#{moment(message.resource.originalarrivaltime).format("MM/DD/YYYY hh:mm:ss")}] <GROUP: #{message.resource.threadtopic}> #{message.resource.imdisplayname}: #{message.resource.content}"
            handleMessageText message.resource.imdisplayname, message.resource.content, message.resource.conversationLink