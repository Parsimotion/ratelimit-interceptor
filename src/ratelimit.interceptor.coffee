isFunction = require "lodash.isfunction"
includes = require "lodash.includes"
Promise = require "bluebird"
async = require "async"
debug = 
  general: require("debug") "ratelimit-interceptor"
  stats: require("debug") "ratelimit-interceptor:stats"

module.exports = class RateLimitInterceptor

  constructor: (concurrency = 1, { toInterceptMethods, toNotInterceptMethods } = {}) ->
    @toInterceptMethods = toInterceptMethods
    @toNotInterceptMethods = toNotInterceptMethods
    @q = async.queue @_doCall, concurrency
    Promise.promisifyAll @q

  get: (target, property, receiver) ->
    if not isFunction(target[property]) or property is 'valueOf' or not @_shouldIntercept(property)
      return target[property] 
    
    (args...) =>
      debug.general "Enqueue [%s]/%d", property, args.length
      debug.stats "%j", @_stats()

      @q.pushAsync { target, method: property, args }
      .finally => debug.stats "%j", @_stats()

  _shouldIntercept: (property) =>
    return includes(@toInterceptMethods, property) if @toInterceptMethods?
    return not includes(@toNotInterceptMethods, property) if @toNotInterceptMethods?
    return true

  _doCall: ({ target, method, args }, callback) =>
    debug.general "Doing call %s - %j", method, args
    debug.stats "%j", @_stats()
    target[method](args...)
    .asCallback callback

  _stats: => { idle: @q.idle(), length: @q.length(), running: @q.running() }