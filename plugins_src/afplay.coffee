{exec} = require 'child_process'

class Afplay

  constructor : (@scope) ->

  getName : ->
    'Afplay'

  onAudioCreate : (filePath) ->
    exec "afplay #{filePath}"

exports.init = (scope) ->
  new Afplay scope