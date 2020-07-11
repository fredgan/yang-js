# Context - control logic binding context

## Context Object
debug = require('debug')('yang:context')
delegate = require 'delegates'

proto = module.exports = {
  use: (name) ->
    # TODO: below is a bit of a hack...
    return @lookup('feature', name)?.binding

  with: (options={}) ->
    @opts ?= {}
    @opts[k] = v for own k, v of options
    return this
    
  at: (key) ->
    ctx = Object.create(this)
    ctx.opts = Object.assign {}, @opts
    ctx.node = @node.in key
    Object.preventExtensions ctx
    return ctx

  push: (data) -> switch @kind
    when 'rpc', 'action' then @node.do(data, @opts)
    else
      oper = switch
        when @opts?.replace is true then 'set'
        else 'merge'
      try await @node[oper](data, @opts).commit(@opts)
      catch err then throw @error err
      return @node
    
  after: (timeout, max) ->
    timeout = parseInt(timeout) || 100
    max = parseInt(max) || 5000
    new Promise (resolve) -> 
      setTimeout (-> resolve(Math.round(Math.min(max, timeout * 1.5)))), timeout

  logDebug: -> @log 'debug', arguments...
  logInfo:  -> @log 'info', arguments...
  logWarn:  -> @log 'warn', arguments...
  logError: -> @log 'error', @error arguments...
    
  log: (topic, args...) ->
    @root.emit('log', topic, args, this)
}

## Property node delegation
delegate proto, 'node'
  .access 'data' # read/write with validations
  .getter 'uri'
  .getter 'name'
  .getter 'kind'
  .getter 'path'
  .getter 'active'
  .getter 'attached' # used for instance-identifier and leafref validations
  .getter 'changes'
  .getter 'change'
  .getter 'schema'
  .getter 'parent'
  .getter 'root'
  .method 'get'
  .method 'error'
  .method 'locate'
  .method 'lookup'
  .method 'find'
  .method 'inspect'
  .method 'toJSON'

## Module delegation
delegate proto, 'root'
  .method 'access'
