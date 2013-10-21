
describe "Service: nxWebsocket", ->

  # instantiate service
  nxWebsocket = undefined

  # load the service's module
  beforeEach module "nx"

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

  it "should have these api methods", ->
    nxWebsocket.should.have.keys [
      "socket"
      "open"
      "connect"
      "connected"
      "publish"
      "subscribe"
      "unsubscribe"
      "request"
      "send"
    ]

  describe "a basic socket", ->
    beforeEach ->
      @socket = nxWebsocket.socket

    it "should have these api methods", ->
      @socket.should.have.keys [
        "uri"
        "protocol"
        "socket"
        "ready"
        "responses"
        "subscribtions"
        "connected"
        "scopes"
        "options"
      ]

  describe "a basic packet", ->

    it "should be send by .send()", ->
      # this is an async test
      done = @async()

      # Generate a mocked WebSocket that will test exactly one use-case
      window.WebSocket = mock
        send: (message) ->
          message.should.be.a.String
          packet = JSON.parse message
          console.log packet
          packet.should.have.keys [
            "uuid"
            "gid"
            "head"
            "body"
          ]
          packet.body.should.eql
            some: 'arbitrary'
            data: 123
          done()
      , (uri, protocol) ->
        # to make this async
        setTimeout (=> @onopen()), 0

      # run the test, it will timeout after 100ms @see async
      nxWebsocket.send
        some: 'arbitrary'
        data: 123

  describe "default nxWebsocket", ->

    it "should try ws://localhost", ->
      done = @async()
      window.WebSocket = mock {}, (uri, protocol) ->
        should.exist uri
        should.not.exist protocol
        uri.should.be.equal 'ws://localhost'
        done()
      nxWebsocket.send()

    it "should be disconnected", ->
      nxWebsocket.connected.should.be.false

    it "should connect when we try to send data", ->
      # this is an async test
      done = @async()

      # Generate a mocked WebSocket that will test exactly one use-case
      window.WebSocket = mock
        # we only test the send method
        send: (message) ->
          packet = (JSON.parse message).body
          packet.test.should.equal 123
          done()
        # the constructor
      , (uri, protocol) ->
        # to make this async
        setTimeout =>
          @should.have.keys [
            'onopen', 'onclose', 'onerror', 'onmessage', 'send'
          ]
          @onopen()
        , 0

      # run the test, it will timeout after 100ms @see async
      nxWebsocket.send test: 123

    it "should be connceted after we send data", ->
      # this is an async test
      done = @async()

      # Generate a mocked WebSocket that will test exactly one use-case
      window.WebSocket = mock
        # we only test the send method
        send: (packet) ->
          nxWebsocket.connected.should.be.true
          done()
        # the constructor
      , (uri, protocol) ->
        # to make this async
        setTimeout =>
          @onopen()
        , 0

      # run the test, it will timeout after 100ms @see async
      nxWebsocket.send test: 123

    it "should be not connceted after an error is emitted", ->
      # this is an async test
      done = @async()

      # Generate a mocked WebSocket that will test exactly one use-case
      window.WebSocket = mock {}
      , (uri, protocol) ->
        # to make this async
        setTimeout =>
          @onerror new Error 'ERROR!'
          nxWebsocket.connected.should.be.false
          done()
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
        send: (message) ->
          packet = (JSON.parse message).body
          packet.should.eql test: 123
          done()
      , -> setTimeout((=> @onopen()), 0)

      nxWebsocket.request
        test: 123
      , ->

    it "should respond by calling the callback", ->
      done = @async()

      window.WebSocket = mock
        send: (message) ->
          @onmessage
            data: message
      , -> setTimeout((=> @onopen()), 0)

      nxWebsocket.request (data) ->
        should.equal data, null
        done()

    describe "$scope things", ->

      $scope = undefined

      beforeEach inject ["$rootScope", ($root) ->
        $scope = $root.$new()
      ]

      it "should emit a 'nxSocket::connect' event on the scope", ->
        done = @async()

        window.WebSocket = mock
          send: (message) ->
            @onmessage
              data: message
        , -> setTimeout((=> @onopen()), 0)

        $scope.$on 'nxSocket::connect', ->
          done()

        nxWebsocket.socket.scopes.push $scope
        nxWebsocket.send test: 123

      it "should emit a 'nxSocket::broadcast' event when a broadcast comes in", ->
        done = @async()

        window.WebSocket = mock
          send: (message) ->
            @onmessage
              data: message
        , -> setTimeout((=> @onopen()), 0)

        $scope.$on 'nxSocket::broadcast', (data) ->
          done()

        nxWebsocket.socket.scopes.push $scope
        nxWebsocket.send test: 123

      it "should emit a 'nxSocket::close' event when onclose is called", ->
        # this is an async test
        done = @async()

        # Generate a mocked WebSocket that will test exactly one use-case
        window.WebSocket = mock {}
        , (uri, protocol) ->
          # to make this async
          setTimeout =>
            @onclose()
          , 0

        # run the test, it will timeout after 100ms @see async
        nxWebsocket.send test: 123
        nxWebsocket.socket.scopes.push $scope

        $scope.$on 'nxSocket::close', (scope, err) ->
          should.not.exist err
          done()

      it "should emit a 'nxSocket::close' event when onerror is called", ->
        # this is an async test
        done = @async()

        # Generate a mocked WebSocket that will test exactly one use-case
        window.WebSocket = mock {}
        , (uri, protocol) ->
          # to make this async
          setTimeout =>
            @onerror new Error 'ERROR!'
          , 0

        # run the test, it will timeout after 100ms @see async
        nxWebsocket.send test: 123
        nxWebsocket.socket.scopes.push $scope

        $scope.$on 'nxSocket::close', (scope, err) ->
          should.exist err
          message = err.message
          message.should.be.equal 'ERROR!'
          done()

      it "should respond by emitting on a $scope", ->
        done = @async()
        window.WebSocket = mock
          send: (message) ->
            @onmessage data: message
        , -> setTimeout((=> @onopen()), 0)

        nxWebsocket.request $scope

        $scope.$on 'nxSocket::response', (scope, data) ->
          should.equal data, null
          done()

      it "should send a configuration message when subscribing", ->
        done = @async()

        window.WebSocket = mock
          send: (message) ->
            packet = JSON.parse message
            packet.head.should.have.keys [
              'pubsub'
            ]
            packet.head.pubsub.should.eql { subscribe: ['channel'] }
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
          head:
            pubsub:
              subscribe: [ 'channel' ]
        ,
          fn: ->
            nxWebsocket.unsubscribe 'channel', $scope
          head:
            pubsub:
              unsubscribe: 'channel'
        ]

        createAsyncWebSocketMock done, async

  describe "configurated nxWebsocket", ->

    it "should connect to ws://different", ->
      done = @async()
      window.WebSocket = mock {}, (uri, protocol) ->
        should.exist uri
        should.not.exist protocol
        uri.should.be.equal 'ws://different'
        done()

      socket = nxWebsocket.connect "ws://different"
      socket.send()

    it "should be able to set a protocol", ->
      done = @async()
      window.WebSocket = mock {}, (uri, protocol) ->
        should.exist uri
        should.exist protocol
        uri.should.be.equal 'ws://different'
        protocol.should.be.a.String
        protocol.should.be.equal 'protocol'
        done()

      socket = nxWebsocket.connect "ws://different", 'protocol'
      socket.send()

    it "should be able to connect with a configuration object", ->
      done = @async()
      window.WebSocket = mock {}, (uri, protocol) ->
        should.exist uri
        should.exist protocol
        uri.should.be.equal 'ws://different'
        protocol.should.be.equal "protocol"
        done()

      socket = nxWebsocket.connect
        uri: "ws://different"
        protocol: "protocol"
      socket.send()




