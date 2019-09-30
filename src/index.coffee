RateLimitInterceptor = require "./ratelimit.interceptor"

module.exports = (obj, concurrency, options) ->
  interceptor = new RateLimitInterceptor concurrency, options
  new Proxy obj, interceptor