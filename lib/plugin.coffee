class Plugin

  @copyOptions : (originOptions, pluginOptions) ->
    for own key, value of pluginOptions
      if originOptions[key] isnt undefined
        pluginOptions[key] = originOptions[key]

  loggingEnabled : false

  bot : null

  pluginId : null

  constructor : (@bot, @pluginId) ->

  getName : -> 'Unknown Plugin name'

  getEventNames : -> []

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->

  log : (event, messages...) ->
    bot?.getEmitter()?.emit @pluginId, event, messages


exports.Plugin = Plugin