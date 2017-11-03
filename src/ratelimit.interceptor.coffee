isFunction = require "lodash.isfunction"
Promise = require "bluebird"
async = require "async"
debug = 
  general: require("debug") "ratelimit-interceptor"
  stats: require("debug") "ratelimit-interceptor:stats"

class RateLimitInterceptor

  constructor: (concurrency) ->
    @q = async.queue @_doCall, concurrency
    Promise.promisifyAll @q

  get: (target, property, receiver) ->
    return target[property] unless isFunction(target[property])
    
    (args...) =>
      debug.general "Enqueue [%s]/%d", property, args.length
      debug.stats "%j", @_stats()

      @q.pushAsync { target, method: property, args }

  _doCall: ({ target, method, args }, callback) =>
    debug.general "Doing call %s - %j", method, args
    debug.stats "%j", @_stats()
    target[method](args...)
    .finally => debug.stats "%j", @_stats()
    .asCallback callback

  _stats: => { idle: @q.idle(), length: @q.length(), running: @q.running() }

module.exports = (obj, concurrency) ->
  interceptor = new RateLimitInterceptor concurrency
  new Proxy obj, interceptor