{File} = require 'file-utils'
fs = require 'fs'

class LocaleTempFileRepository

  items : null

  constructor : (@items = {}) ->
    setInterval (=> @gc()), 60000

  gc : ->
    console.log 'LocaleTempFileRepository.gc'
    now = new Date()
    validUntil = now - 60
    for id, item of @items #when item.created < validUntil
      filePath = @items[id].filePath
      console.info item.created.getTime(), validUntil
      console.log "LocaleTempFileRepository.gc >> Deleting #{filePath}..."
      @remove id
    return

  add : (id) ->
    @items[id] =
      filePath : new File('../' + id).getAbsolutePath()
      created : new Date()

  remove : (id) ->
    if @items[id]
      fs.unlink @items[id].filePath, => delete @items[id]
    return

  exist : (id) ->
    @items[id] isnt undefined

  get : (id) ->
    if @exist id
      @items[id].filePath

exports.LocaleTempFileRepository = LocaleTempFileRepository