OptParse = require 'optparse'
http = require 'http'
{Plugin} = require '../lib/plugin'

Switches = [
  [ '-nabaztagat', '--nabaztag-api-token VALUE', 'The Nabaztag api token']
]

Options =
  apiToken : ''
  nabaztagApiHostName : 'www.nabaztag.com'
  nabaztagApiHostPort : 80


Parser = new OptParse.OptionParser Switches
Parser.banner = "Usage of Plugin Nabaztag:"

Parser.on "nabaztag-api-token", (opt, value) ->
  Options.apiToken = value


class Nabaztag extends Plugin

#intellij formatter workaround
  _ : undefined

  # the required api token to send messages to the rabbit
  apiToken : null

  getEventNames : -> ['nabaztag.command.sent']

  setApiToken : (@apiToken) ->

  getName : ->
    'Nabaztag'

  sendCommand : (command) ->
    url = "/nabaztags/#{@apiToken}/#{command}"
    options =
      host : Options.nabaztagApiHostName
      port : Options.nabaztagApiHostPort
      path : url
      method : 'GET'
    http.request(options, @onApiRequest).end()
    @bot.getEmitter().emit 'nabaztag.command.sent', command
    if @isLoggingEnabled() then console.log "Nabaztag.sendCommand #{command}"
    return

  onApiRequest : (response) -> return

  sendPlayAudioCommand : (url) ->
    @sendCommand "play?url=#{url}"

  onAudioCreate : (fileName) ->
    plugin = @bot.getPlugin 'http'
    if plugin
      url = plugin.getPublicPath fileName
      @sendPlayAudioCommand url
    else
      console.warn 'Plugin http is missing.'


###
  Exports & Plugin Interface
###

exports.help = () ->
  console.log Parser.toString()

exports.init = (bot, argv, options) ->
  if options
    Plugin.copyOptions options, Options
  else
    Parser.parse argv

  plugin = new Nabaztag bot
  plugin.setApiToken Options.apiToken

  bot.getEmitter().on 'audio.create', (filePath, fileName) ->
    plugin.onAudioCreate fileName

  return plugin