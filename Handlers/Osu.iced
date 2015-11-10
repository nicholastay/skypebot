# osu! stats and stuff

class exports.Osu
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.command', @handleCommand

    handleCommand: (username, displayName, command, cmdArgs, conversationUrl) =>
        if command is '~osurank'
            username = if cmdArgs then cmdArgs else 'Nexerq'
            await @SkypeBot.Clients.OsuApi.getUser @SkypeBot.Clients.OsuApi.user.byUsername(username), defer err, resp
            return @SkypeBot.Clients.Skype.sendMessage conversationUrl, 'There was an error with the osu! api. Please try again later.' if err
            @SkypeBot.Clients.Skype.sendMessage conversationUrl, """#{resp.username}'s osu! stats: (https://osu.ppy.sh/u/#{resp.user_id})
                                                                    PP: #{resp.pp_raw}pp, Accuracy: #{parseFloat(resp.accuracy).toFixed(2)}%
                                                                    Rank: ##{resp.pp_rank} (Global), ##{resp.pp_country_rank} (#{resp.country})
                                                                    Total score: #{resp.total_score}, Level: #{parseInt(resp.level)}
                                                                    Playcount: #{resp.playcount} plays"""