{exec} = require 'child_process'


class Afplay

  constructor : (@bot) ->

  getName : ->
    'Afplay'

  onAudioCreate : (filePath) ->
    exec "afplay #{filePath}"


###
  Exports & Plugin Interface
###

exports.init = (bot) ->
  plugin = new Afplay bot

  bot.getEmitter().on 'audio.create', (filePath) ->
    plugin.onAudioCreate filePath

  return plugin