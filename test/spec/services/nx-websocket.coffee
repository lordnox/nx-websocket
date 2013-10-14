"use strict"

describe "Service: nxWebsocket", ->
  
  # instantiate service
  nxWebsocket = undefined

  # load the service's module
  beforeEach module "nxWebsocketApp"

  beforeEach inject ["nxWebsocket", (_nxWebsocket_) ->
    nxWebsocket = _nxWebsocket_
  ]

  beforeEach ->    
    @async = (msg, timeout) ->
      called = false
      done = -> called = true
      if typeof msg is 'number'
        timeout = msg
        msg = undefined      
      waitsFor ->
        called
      , msg, timeout || 100
      done


  it "should be able to connect to a webSocket", ->
    nxWebsocket.should.have.keys [
      "socket"
    , "open"
    , "connect"
    , "publish"
    , "subscribe"
    , "unsubscribe"
    , "request"
    , "send"
    ]

  describe "default websocket", ->
    it "should try ws://localhost", ->
      done = @async()
      window.WebSocket = mock {}, (uri, header) ->
        should.exist uri
        should.exist header
        uri.should.be.equal 'ws://localhost'
        header.should.be.an.Array
        header.should.have.length 0
        done()
      nxWebsocket.send()

  describe "class: nxWebsocket", ->
    it "should send data via the WebSocket send method, after connecting", ->
      # this is an async test
      done = @async()

      # Generate a mocked WebSocket that will test exactly one use-case
      window.WebSocket = mock 
        # we only test the send method
        send: (packet) ->
          packet.should.have.keys [
            'uuid'
          , 'test'
          ]
          packet.test.should.equal 123
          done()
        # the constructor
      , (uri, header) ->
        # to make this async
        setTimeout =>
          @should.have.keys [
            'onopen', 'onclose', 'onerror', 'onmessage', 'send'
          ]
          @onopen()
        , 0
      
      # run the test, it will timeout after 100ms @see async
      nxWebsocket.send test: 123

    it "should throw when incorrectly sending a request", ->
      # reset the WebSocket mock
      window.WebSocket = ->
      (->
        nxWebsocket.request()
      ).should.throw()
      (->
        nxWebsocket.request test: 123
      ).should.throw()
      (->
        nxWebsocket.request
          test: 123
        , ->
      ).should.not.throw()

    it "should send a correct packet for a request", ->
      done = @async()

      window.WebSocket = mock
        send: (packet) ->
          packet.data.should.eql test: 123
          done()
      , -> setTimeout((=> @onopen()), 0)

      nxWebsocket.request
        test: 123
      , ->

    it "should respond by calling the callback", ->
      done = @async()

      window.WebSocket = mock
        send: (packet) ->
          @onmessage packet
      , -> setTimeout((=> @onopen()), 0)

      nxWebsocket.request (data) ->
        should.equal data, null
        done()

    describe "$scope things", ->

      $scope = undefined

      beforeEach inject ["$rootScope", ($root) ->
        $scope = $root.$new()
      ]

      it "should respond by emitting on a $scope", ->
        done = @async()
        window.WebSocket = mock
          send: (packet) ->
            @onmessage packet
        , -> setTimeout((=> @onopen()), 0)

        nxWebsocket.request $scope

        $scope.$on 'nxSocket::response', (scope, data) ->
          should.equal data, null
          done()

      it "should send a configuration message when subscribing", ->
        done = @async()

        window.WebSocket = mock 
          send: (packet) ->
            packet.should.have.keys [
              'uuid'
            , 'pubsub'
            ]
            packet.pubsub.should.eql { subscribe: ['channel'] }
            done()
        , -> setTimeout((=> @onopen()), 0)
        
        nxWebsocket.subscribe 'channel', $scope

      it "should have the $scope in the subscribtion list", ->
        window.WebSocket = mock 
        nxWebsocket.subscribe 'channel', $scope
        nxWebsocket.socket.subscribtions.channel.should.have.length 1

      it "should throw when subscribing without $scope", ->
        (->
          nxWebsocket.subscribe 'channel'
        ).should.throw()

      it "should send no configuration message when unsubscribing from channel not subscribed to", ->
        done = @async()

        notCalled = true

        window.WebSocket = mock -> notCalled = false

        nxWebsocket.unsubscribe 'channel'

        # wait 10ms for something to happen
        setTimeout ->
          notCalled.should.be.true
          done()
        , 10

      it "should send a configuration message when unsubscribing a channel subscribed to", ->
        done = @async()

        async = [
          fn: ->        
            nxWebsocket.subscribe 'channel', $scope
          packet: 
            subscribe: [ 'channel' ] 
        ,
          fn: ->        
            nxWebsocket.unsubscribe 'channel', $scope
          packet: 
            unsubscribe: 'channel'
        ]

        createAsyncWebSocketMock done, async

