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



get-name = (name, m) ->
  # `m` is the module object, with these attributes:
  #   .filename = /Users/yagamy/Works/workspaces/t2t/yapps-tt/tests/test01/lib/dummy-plugin.ls
  #   .parent.filename = /Users/yagamy/Works/workspaces/t2t/yapps-tt/tests/test01/app.ls
  #
  # `name` is the string used in `require` statement, might be
  #   - ./lib/dummy-plugin
  #   - test
  #   - ./abc
  #   - ./lib/test
  #
  {caches, app-filename} = module
  parent-name = m.parent.filename
  if name == path.basename name or parent-name == app-filename
    name = path.basename name
    caches[m.filename] = name: name, entry: yes, m: m
  else
    ext-name = path.extname m.filename
    base-name = path.basename m.filename, ext-name
    if caches.hasOwnProperty parent-name
      p = caches[parent-name]
      caches[m.filename] = name: p.name, m: m
      return name: p.name, entry: no, basename: base-name
    else
      return name: "unknown", entry: no, basename: base-name

module.exports = exports =

  init: (app-filename) ->
    module.app-filename = app-filename


  set-logger-class: (logger-class) ->
    module.logger-class = if logger-class? then logger-class else SimpleLogger


  get-logger: (name, m) ->
    {logger-class} = module
    n = get-name name, m
    if n.name == "unknown"
      console.log "[get-logger] name = #{name}"
      console.log "[get-logger] m.filename = #{m.filename}"
      console.log "[get-logger] m.parent.filename = #{m.parent.filename}"
      console.log "[get-logger] app-filename = #{module.app-filename}"

    base-name = if n.entry then null else n.basename
    logger = new loggerClass n.name, base-name
    get = (logger, level) -> return -> logger[level].apply logger, arguments
    return
      DBG: get logger, \debug
      ERR: get logger, \error
      WARN: get logger, \warn
      INFO: get logger, \info


module.logger-class = SimpleLogger
module.caches = {}
