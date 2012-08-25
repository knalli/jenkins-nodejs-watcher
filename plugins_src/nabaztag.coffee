class Nabaztag

  constructor : (@scope) ->

  getName : ->
    'Nabaztag'

  onAudioCreate : (filePath) ->
    console.log "Nabaztag will play #{filePath}"

exports.init = (scope) ->
  new Nabaztag scope