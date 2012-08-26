{File} = require 'file-utils'
fs = require 'fs'

class LocaleTempFileRepository

  items : null

  constructor : (@items = {}) ->
    setInterval (=> @gc()), 60000

  gc : ->
    now = new Date()
    validUntil = now - 60
    for id, item of @items when item.created.getTime() < validUntil
      filePath = @items[id].filePath
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