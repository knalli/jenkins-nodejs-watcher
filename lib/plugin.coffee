class Plugin

  @copyOptions : (originOptions, pluginOptions) ->
    for own key, value of pluginOptions
      if originOptions[key] isnt undefined
        pluginOptions[key] = originOptions[key]

  loggingEnabled : false

  constructor : (@bot) ->

  getName : -> 'Unknown Plugin name'

  getEventNames : -> []

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->


exports.Plugin = Plugin