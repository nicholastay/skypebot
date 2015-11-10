# Weather via yahoo sql style thingy
request = require 'request'

class exports.Weather
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.command', @handleCommand

    handleCommand: (username, displayName, command, cmdArgs, conversationUrl) =>
        if command is '~weather'
            location = if cmdArgs then location = cmdArgs else location = 'Melbourne'

            await request 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22' + location + '%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys', defer err, resp, body
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'There was an error with the Yahoo! Developer API. Please try again later.' if err or resp.statusCode isnt 200
            body = JSON.parse body
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, "#{displayName}, you have entered an invalid location. Please try again or fuck off if you're not even trying to give a valid place." if not body.query.results
            @SkypeBot.Clients.Skype.sendMessage conversationUrl, "#{displayName}! As requested, the current Weather #{body.query.results.channel.item.title} is #{body.query.results.channel.item.condition.text} with a temperature of #{@SkypeBot.Tools.fahrenheitToCelsius(body.query.results.channel.item.condition.temp).toFixed(0)}C. (powered by the Yahoo! Developer API)"