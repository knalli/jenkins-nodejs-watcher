OptParse = require 'optparse'
http = require 'http'

Switches = [
  [ '-nabaztagat', '--nabaztag-api-token VALUE', 'The Nabaztag api token']
  # this option will be dismissed later in favor of an plugin "http server"
  [ '-nabaztagpln', '--nabaztag-public-localhost-name VALUE', 'Define the hostname (or addr) of this machine to allow access to the audio files. Default is "localhost".']
  # this option will be dismissed later in favor of an plugin "http server"
  [ '-nabaztagplp', '--nabaztag-public-localhost-port VALUE', 'Define the port of this machine to allow access to the audio files. Default is "80".']
]

Options =
  apiToken : ''
  publicLocalhostName : 'localhost'
  publicLocalhostPort : 80
  nabaztagApiHostName : 'www.nabaztag.com'
  nabaztagApiHostPort : 80


Parser = new OptParse.OptionParser Switches
Parser.banner = "Usage of Plugin Nabaztag:"

Parser.on "nabaztag-api-token", (opt, value) ->
  Options.apiToken = value

Parser.on "nabaztag-public-localhost-name", (opt, value) ->
  Options.publicLocalhostName = value

Parser.on "nabaztag-public-localhost-port", (opt, value) ->
  Options.publicLocalhostPort = value


class Nabaztag

#intellij formatter workaround
  _ : undefined

  # an instance of the bot
  bot : null

  # the required api token to send messages to the rabbit
  apiToken : null

  constructor : (@bot, @apiToken) ->

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

exports.init = (bot, argv) ->
  Parser.parse argv

  plugin = new Nabaztag bot, Options.apiToken

  bot.getEmitter().on 'audio.create', (filePath, fileName) ->
    plugin.onAudioCreate fileName

  return plugin