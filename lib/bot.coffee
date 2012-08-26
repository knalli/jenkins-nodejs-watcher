class Bot

  loggingEnabled : false

  constructor : (@emitter)->
    @init()

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->

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
    pluginPath = "../plugins/#{pluginId}"
    module = require pluginPath
    plugin = module.init @, process.argv
    plugin.setLoggingEnabled @isLoggingEnabled()
    console.log "JenkinsServer.loadPlugin #{plugin.getName()}"
    if plugin.getEventNames().length
      console.log "The plugin #{plugin.getName()} exposes following events: #{plugin.getEventNames()}"
    @plugins[pluginId] = plugin

  getPlugin : (pluginId) ->
    @plugins[pluginId]

  init : ->
    console.log 'Bot initialized.'

exports.Bot = Bot