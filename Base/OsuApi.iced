Osu = require 'nodesu'

class exports.OsuApi
    constructor: (@SkypeBot) ->
        @client = @SkypeBot.Clients.OsuApi = new Osu.api
            apiKey: @SkypeBot.Config.osu.apikey