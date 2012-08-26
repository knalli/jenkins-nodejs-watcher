{File} = require 'file-utils'

class LocaleTempFileRepository

  items : null

  constructor : (@items = []) ->
    setInterval (=> @gc()), 60000

  gc : ->
    console.log 'LocaleTempFileRepository.gc'
    now = new Date()
    validUntil = now - 60
    for id, item in @items when item.created < validUntil
      console.log "LocaleTempFileRepository.gc >> Deleting #{@items[id].filePath}"
      new File(@items[id]).delete()
      @items[id] = null
    return

  add : (id) ->
    @items[id] =
      filePath : new File(id).getAbsolutePath()
      created : new Date()

  remove : (id) ->
    if @items[id]
      new File(@items[id].filePath).delete()
    return

  exist : (id) ->
    @items[id] isnt undefined

  get : (id) ->
    if @exist id
      @items[id].filePath

exports.LocaleTempFileRepository = LocaleTempFileRepository