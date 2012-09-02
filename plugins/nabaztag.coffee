http = require 'http'
{Plugin} = require '../lib/plugin'


config =
  options :
    'api-token' :
      alias : 'at'
      value : true
      description : 'The Nabatag api token'
      parse : (opt, value) -> value
    'api-host-name' :
      alias : 'hn'
      default : 'www.nabaztag.com'
      value : true
      parse : (opt, value) -> value
    'api-host-port' :
      alias : 'hn'
      default : 80
      value : true
      parse : (opt, value) -> value


class Nabaztag extends Plugin

#intellij formatter workaround
  _ : undefined

  getEventNames : -> ['nabaztag.command.sent']

  getName : ->
    'Nabaztag'

  sendCommand : (command) ->
    url = "/nabaztags/#{@options['api-token']}/#{command}"
    options =
      host : @options['api-host-name']
      port : @options['api-host-port']
      path : url
      method : 'GET'
    http.request(options, @onApiRequest).end()
    @bot.getEmitter().emit 'nabaztag.command.sent', command
    @log 'commandSent', command
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


### Exports & Plugin Interface ###

exports.config = config

exports.init = (bot, pluginId) ->
  plugin = new Nabaztag bot, pluginId

  bot.getEmitter().on 'audio.create', (filePath, fileName) ->
    plugin.onAudioCreate fileName

  return plugin