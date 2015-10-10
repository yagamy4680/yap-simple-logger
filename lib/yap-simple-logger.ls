#
# Simple Logger
#
require! <[moment colors path]>

log-levels =
  \info :
    string: \INFO .green
  \debug :
    string: 'DBG '.blue
  \error :
    string: 'ERR '.red
  \warn :
    string: \WARN .yellow



class SimpleLogger
  (@module-name, @base-name) ->
    return

  format-name: ->
    name = if @base-name? then "#{@module-name}::#{@base-name}" else "#{@module-name}"
    len = name.length
    xs = [' ' for x from 1 to 16 - len ]
    return "#{name}#{xs.join ''}"

  log: (lv, err, message) ->
    name = @.format-name!
    msg = if message? then message else err
    level = log-levels[lv]
    now = moment! .format 'YYYY/MM/DD HH:mm:ss'
    prefix = "#{now.gray} #{name} [#{level.string}]"
    console.error "#{prefix} #{err.stack}" if message?
    console.error "#{prefix} #{msg}"

  error: (err, message) -> return @.log \error, err, message
  info: (err, message) -> return @.log \info, err, message
  warn: (err, message) -> return @.log \warn, err, message
  debug: (err, message) -> return @.log \debug, err, message


module.logger-class = SimpleLogger
module.caches = {}


module.exports = exports =
  init: (app-filename, yap-filename) ->
    module.app-filename = app-filename
    module.app-dirname = path.dirname app-filename
    if yap-filename?
      tokens = yap-filename.split path.sep
      tokens.pop!
      tokens.pop!
      tokens.pop!
      module.yap-dirname = tokens.join path.sep
      console.log "yap-dirname = #{module.yap-dirname}"

  set-logger-class: (logger-class) ->
    module.logger-class = if logger-class? then logger-class else SimpleLogger




parse-filename = (filename) ->
  {app-dirname, app-filename, yap-dirname} = module
  ext-name = path.extname filename
  base-name = path.basename filename, ext-name
  return name: \__app__, basename: null if filename == app-filename
  if filename.starts-with app-dirname
    filename = filename.substring app-dirname.length
    tokens = filename.split path.sep
    if tokens.length == 2
      # E.g. /apps/sensor-web/test.ls    => name: '__test__'
      return name: "__#{base-name}__", basename: null
    else if tokens.length == 3
      # E.g. /apps/sensor-web/lib/xyz.ls => name: 'xyz'
      return name: base-name, basename: null
    else if tokens.length == 4
      # E.g. /apps/sensor-web/lib/def/good.ls => name: 'def', basename: 'good'
      return name: tokens[2], basename: base-name
    else
      # E.g. /apps/sensor-web/lib/foo/bar/great.ls => name: 'bar', basename: 'great'
      return name: "...#{tokens[tokens.length - 2]}", basename: base-name
  else
    return name: "??", basename: base-name unless yap-dirname? and filename.starts-with yap-dirname
    filename = filename.substring yap-dirname.length
    tokens = filename.split path.sep
    # E.g. /externals/y-modules/sensorhub-client/lib/sensorhub-client.ls => name: 'sensorhub-client'
    return name: tokens[1], basename: null if tokens[1] == base-name
    # E.g. /externals/y-modules/sensorhub-client/lib/helper.ls => name: 'sensorhub-client', basename: 'helper'
    return name: tokens[1], basename: base-name



global.get-logger = (filename) ->
  {logger-class} = module
  {name, basename} = parse-filename filename
  logger = new loggerClass name, basename
  get = (logger, level) -> return -> logger[level].apply logger, arguments
  return
    DBG: get logger, \debug
    ERR: get logger, \error
    WARN: get logger, \warn
    INFO: get logger, \info

