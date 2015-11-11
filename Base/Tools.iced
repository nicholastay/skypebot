moment = require 'moment-timezone'

class exports.Tools
    constructor: (@SkypeBot) ->

    # From some math question or something lmao
    fahrenheitToCelsius: (degrees) -> return (+degrees - 32) * (5 / 9)

    # https://stackoverflow.com/questions/18251399/why-doesnt-encodeuricomponent-encode-sinlge-quotes-apostrophes
    rfc3986EncodeURI: (str) -> return encodeURI(str).replace(/[!'()*]/g, escape)

    # More readability for setTimeout
    delay: (ms, func) -> setTimeout func, ms

    # https://stackoverflow.com/questions/2532218/pick-random-property-from-a-javascript-object
    randomProperty: (obj) ->
        keys = Object.keys obj
        return obj[keys[keys.length * Math.random() << 0]]

    # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
    getRandomInt: (min, max) -> return Math.floor(Math.random() * (max - min)) + min

    formattedTime: -> return moment().format("MM/DD/YYYY hh:mm:ss")

    secondsToMinSecs: (seconds) -> return {minutes: Math.floor(seconds / 60), seconds: seconds % 60}

    isAdmin: (username) ->
        return true if username is @SkypeBot.Config.skype.username
        return true if username in @SkypeBot.Config.admins
        return false

    # for shits and giggles
    generateQuote: (username, displayname, timestamp, message) ->
        # <quote author="USERNAME" authorname="DISPLAY NAME" timestamp="TIMESTAMP, WITHOUT LAST 3 DIGITS"><legacyquote>[5:53:54 PM] DISPLAYNAME: </legacyquote>MESSAGE HERE<legacyquote>\r\n\r\n&lt;&lt;&lt; </legacyquote></quote>
        return "<quote author=\"#{username}\" authorname=\"#{displayname}\" timestamp=\"#{timestamp}\"><legacyquote>[#{moment(timestamp).format('h:mm:ss A')}] #{displayname}: </legacyquote>#{message}<legacyquote>\r\n\r\n&lt;&lt;&lt; </legacyquote></quote>"