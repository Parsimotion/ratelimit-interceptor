Promise = require "bluebird"
RateLimitInterceptor = require "./ratelimit.interceptor"
interceptor = require "./index"
should = require "should"
sinon = require "sinon"
require "should-sinon"

describe "RateLimit Interceptor", ->

  { client } = {}

  interceptWith = (promise, concurrency, opts = {}) ->
    client = { m1: sinon.stub().returns(promise) }
    interceptor client, concurrency, opts

  it "should called to original method", ->
    param = "A parameter"
    client = { m1: sinon.stub().returns Promise.resolve(10) }
    interceptObject = interceptor client, 1
    interceptObject.m1(param).tap -> client.m1.should.be.calledOnce().calledWith param

  describe "use concurrency", ->

    beforeEach ->
      Promise.setScheduler (f) => setTimeout f, 0

    it "should be use concurrency", -> 
      stub = 
        sinon.stub()
        .onFirstCall().returns Promise.resolve().delay(40)
        .onSecondCall().returns Promise.resolve().delay(20)

      client = m1: stub
      interceptObject = interceptor client, 1
      
      $promises = Promise.all [
        interceptObject.m1(1)
        interceptObject.m1(2)
      ]

      Promise.resolve()
      .delay 10
      .tap -> client.m1.should.be.calledOnce()
      .delay 70
      .tap -> client.m1.getCall(0).should.be.calledWith 1
      .tap -> client.m1.getCall(1).should.be.calledWith 2

  describe "To or to not intercept methods", ->

    assertion_evaluator = (itQuote, shouldIntercept, opts)   =>
      it itQuote, ()->
        rateLimitInterceptor = new RateLimitInterceptor(1, opts)
        rateLimitInterceptor._shouldIntercept("test").should.be[shouldIntercept]()

    assertion_evaluator(
      "should always intercept if the opts are empty",
      true
    )

    assertion_evaluator(
      "should intercept if the method is in the toInterceptMethods list",
      true, { toInterceptMethods: ["test"] }
    )

    assertion_evaluator(
      "should intercept if the method isn't in any of the lists",
      true, { toNotInterceptMethods: ["oneMethod"], toInterceptMethods: ["otherMethod"] }
    )

    assertion_evaluator(
      "should not intercept if the method in not in the toInterceptMethods list and there is no toNotInterceptMethods",
      false, { toInterceptMethods: ["method"] }
    )

    assertion_evaluator(
      "should not intercept if the method is in the toNotInterceptMethods list",
      false, { toNotInterceptMethods: ["test"] }
    )

    assertion_evaluator(
      "should not intercept if the method is in the toNotInterceptMethods list and not in the other",
      false, { toNotInterceptMethods: ["test"], toInterceptMethods: ["oneMethod"] }
    )
