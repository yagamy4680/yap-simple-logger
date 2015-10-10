#
# Simple Logger
#
require! <[moment colors]>

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
  (@name) ->
    return

  log: (lv, err, message) ->
    {name} = @
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




module.exports = exports =

  set-logger-class: (logger-class) ->
    module.logger-class = if logger-class? then logger-class else SimpleLogger


  get-logger: (name) ->
    {logger-class} = module
    logger = new loggerClass name
    get = (logger, level) -> return -> logger[level].apply logger, arguments
    return
      DBG: get logger, \debug
      ERR: get logger, \error
      WARN: get logger, \warn
      INFO: get logger, \info



module.logger-class = SimpleLogger
