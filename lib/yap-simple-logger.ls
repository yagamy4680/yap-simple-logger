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


parse-filename = (filename) ->
  {app-dirname, app-filename, y-module-dir} = module
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
    if y-module-dir? and filename.starts-with y-module-dir
      filename = filename.substring y-module-dir.length
      tokens = filename.split path.sep
      # E.g. /externals/y-modules/sensorhub-client/lib/sensorhub-client.ls => name: 'sensorhub-client'
      return name: tokens[1], basename: null if tokens[1] == base-name
      # E.g. /externals/y-modules/sensorhub-client/lib/helper.ls => name: 'sensorhub-client', basename: 'helper'
      return name: tokens[1], basename: base-name
    else
      idx = filename.index-of 'yapps-plugins'
      if idx >= 0
        # E.g. /externals/yapps-plugins/communicator/lib/tcp.ls => name: 'communicator', basename: 'tcp'
        tokens = filename.substring idx .split path.sep
        return name: tokens[1], basename: base-name
      else
        return name: "??", basename: base-name unless idx >= 0



class Driver
  (@module-name, @base-name) ->
    return


class ConsoleDriver extends Driver
  (@module-name, @base-name) ->
    return super module-name, base-name

  format-name: ->
    {paddings} = module
    name = if @base-name? then "#{@module-name}::#{@base-name}" else "#{@module-name}"
    len = name.length
    padding = if len <= 24 then paddings[24 - len] else ""
    return "#{name}#{padding}"

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



class Logger
  (@module-name, @base-name, driver-class) ->
    @.set-driver-class driver-class
    return

  set-driver-class: (driver-class) ->
    @driver = new driver-class @module-name, @base-name

  debug: -> return @driver.debug.apply @driver, arguments unless global.argv?.v? and not global.argv.v
  info: -> return @driver.info.apply @driver, arguments
  warn: -> return @driver.warn.apply @driver, arguments
  error: -> return @driver.error.apply @driver, arguments


module.paddings = [""] ++ [ ([ ' ' for y from 1 to x ]).join '' for x from 1 to 24 ]
module.loggers = []
module.driver-class = ConsoleDriver

module.exports = exports =
  init: (app-filename, yap-filename) ->
    module.app-filename = app-filename
    module.app-dirname = path.dirname app-filename
    if yap-filename?
      tokens = yap-filename.split path.sep
      tokens.pop!
      tokens.pop!
      tokens.pop!
      module.y-module-dir = tokens.join path.sep
      console.error "y-module-dir = #{module.y-module-dir}"

  set-driver-class: (driver-class) ->
    console.error "set-driver-class"
    {loggers} = module
    [ l.set-driver-class driver-class for l in loggers ]
    module.driver-class = driver-class if driver-class?

  base-driver: Driver


global.get-logger = (filename) ->
  {driver-class, loggers} = module
  {name, basename} = parse-filename filename
  logger = new Logger name, basename, driver-class
  loggers.push logger
  get = (logger, level) -> return -> logger[level].apply logger, arguments
  return
    DBG: get logger, \debug
    ERR: get logger, \error
    WARN: get logger, \warn
    INFO: get logger, \info
