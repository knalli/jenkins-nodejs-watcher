class Bot

  constructor : (@emitter)->
    @init()

  plugins : []

  loadPlugins : (pluginIds...) ->
    if Object.prototype.toString.call(pluginIds[0]) is '[object Array]'
      for pluginId in pluginIds[0]
        @loadPlugin pluginId
    else
      for pluginId in pluginIds
        @loadPlugin pluginId

  loadPlugin : (pluginId) ->
    pluginPath = "../plugins_src/#{pluginId}"
    module = require pluginPath
    plugin = module.init @
    console.log "JenkinsServer.loadPlugin #{plugin.getName()}"
    @plugins.push plugin

  init : ->
    @emitter.on 'audio.create', (filePath) =>
      for plugin in @plugins when plugin.onAudioCreate
        plugin.onAudioCreate filePath

exports.Bot = Bot