# Youtube link stuff
request = require 'request'

# yeah i figured this out myself q.q
# im bad at regex yeah thx
ytVidRegex = /((youtube\.com\/watch\?v=)|(youtu\.be\/))([A-Za-z0-9-_]+)/i

class exports.Youtube
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message', @handleMessage

    handleMessage: (username, displayName, message, conversationUrl) =>
        # Temp disable youtube links; maybe convo specific settings in the future
        if username is @SkypeBot.Config.skype.username
            if message is '~disableYoutubeLinks'
                @SkypeBot.Config.youtubeLinkHandling = false
                return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'YouTube link handling has been disabled globally.'
            else if message is '~enableYoutubeLinks'
                @SkypeBot.Config.youtubeLinkHandling = true
                return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'YouTube link handling has been enabled globally.'
        
        return if @SkypeBot.Config.youtubeLinkHandling is false

        ytVidMatch = ytVidRegex.exec message
        if ytVidMatch
            videoId = ytVidMatch[4]

            await request "https://www.googleapis.com/youtube/v3/videos?part=snippet&key=#{@SkypeBot.Config.google.apikey}&id=#{videoId}", defer err, resp, body
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'There was an error with the Google YouTube API. Please try again later.' if err or resp.statusCode isnt 200
            body = JSON.parse body
            return if body.items.length < 1 # ignore stupid links that don't work
            @SkypeBot.Clients.Skype.sendMessage conversationUrl, """YouTube link detected! Here's some information:
                                                                    (sent by #{displayName})
                                                                    Title: #{body.items[0].snippet.title}
                                                                    Channel: #{body.items[0].snippet.channelTitle}"""