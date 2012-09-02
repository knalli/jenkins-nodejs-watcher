{exec} = require 'child_process'
{Plugin} = require '../lib/plugin'


class Afplay extends Plugin

  getName : -> 'Afplay'

  onAudioCreate : (filePath) -> exec "afplay #{filePath}"


### Exports & Plugin Interface ###

exports.init = (bot, pluginId) ->
  plugin = new Afplay bot, pluginId

  bot.getEmitter().on 'audio.create', (filePath) ->
    plugin.onAudioCreate filePath

  return plugin