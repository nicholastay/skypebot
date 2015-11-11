# osu! stats and stuff

osuMapRegex = /osu.ppy.sh\/(s|b)\/(\d+)/i

class exports.Osu
    constructor: (@SkypeBot) ->
        @SkypeBot.Events.on 'skype.message.command', @handleCommand
        @SkypeBot.Events.on 'skype.message', @handleMessage

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

    handleMessage: (username, displayName, message, conversationUrl) =>
        osuMapMatch = osuMapRegex.exec message
        if osuMapMatch
            mapType = osuMapMatch[1] # s/b set beatmap
            mapID = osuMapMatch[2] # id
            console.log "osu! - Attempting to get map #{mapType}-#{mapID}..."
            await @SkypeBot.Clients.OsuApi.getBeatmaps @SkypeBot.Clients.OsuApi.beatmap.byLetter(mapID, mapType), @SkypeBot.Clients.OsuApi.mode.all, defer err, resp 
            return console.log " osu! - Something went wrong with osu! api. (#{err})" if err
            return if resp.length < 1 # No such map, blank response

            map = resp[0] # First diff in the set
            status = @SkypeBot.Clients.OsuApi.beatmap.approvalStatus[map.approved]
            length = @SkypeBot.Tools.secondsToMinSecs map.total_length
            
            @SkypeBot.Clients.Skype.sendMessage conversationUrl, """osu! map detected. Here's some information on the map:
                                                                    Beatmap status: #{status}
                                                                    Song: #{map.artist} - #{map.title}, Diff: #{map.version}
                                                                    Diff info: CS#{map.diff_size} AR#{map.diff_approach} OD#{map.diff_overall} HP#{map.diff_drain} #{(+map.difficultyrating).toFixed(2)}★
                                                                    Mapped by: #{map.creator}, BPM: #{map.bpm}bpm, Length: #{length.minutes}:#{length.seconds}"""