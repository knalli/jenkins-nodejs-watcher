class Bot

  constructor : (@emitter)->
    @init()

  getEmitter : -> @emitter

  plugins : null

  loadPlugins : (pluginIds...) ->
    @plugins = {}
    if Object.prototype.toString.call(pluginIds[0]) is '[object Array]'
      for pluginId in pluginIds[0]
        @loadPlugin pluginId
    else
      for pluginId in pluginIds
        @loadPlugin pluginId

  loadPlugin : (pluginId) ->
    pluginPath = "../plugins_src/#{pluginId}"
    module = require pluginPath
    plugin = module.init @, process.argv
    console.log "JenkinsServer.loadPlugin #{plugin.getName()}"
    @plugins[pluginId] = plugin

  getPlugin : (pluginId) ->
    @plugins[pluginId]

  init : ->

exports.Bot = Bot