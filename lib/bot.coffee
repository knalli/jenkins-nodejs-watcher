class Bot

  loggingEnabled : false

  constructor : (@emitter, @options)->
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
    plugin = module.init @, process.argv, if @options.config then @options.plugins[pluginId]
    plugin.setLoggingEnabled @isLoggingEnabled()
    if @isLoggingEnabled() then console.log "Bot.loadPlugin #{plugin.getName()}"
    if plugin.getEventNames().length
      if @isLoggingEnabled() then console.log "The plugin #{plugin.getName()} exposes following events: #{plugin.getEventNames()}"
    @plugins[pluginId] = plugin

  getPlugin : (pluginId) ->
    @plugins[pluginId]

  init : ->
    if @isLoggingEnabled() then console.log 'Bot initialized.'

exports.Bot = Bot