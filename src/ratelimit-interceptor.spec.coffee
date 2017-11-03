Promise = require "bluebird"
interceptor = require "./ratelimit.interceptor"
should = require "should"
sinon = require "sinon"
require "should-sinon"


describe "RateLimit Interceptor", ->

  { client } = {}

  interceptWith = (promise, concurrency) ->
    client = { m1: sinon.stub().returns(promise) }
    interceptor client, concurrency

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
