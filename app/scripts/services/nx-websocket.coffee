"use strict"

app = null
try
  app = angular.module "nx"
catch
  app = angular.module "nx", []


app.provider "nxWebsocket", NxWebsocket = ->

  # hash for all open sockets
  openSockets = {}

  # simple internal uuid method
  uuid = -> Math.random()

  isScope = (scope) ->
    typeof scope is 'object' and typeof scope.$emit is 'function'

  config =
    uri: 'ws://localhost'
    protocol: undefined
    timeout: 500
    socket:
      emit      : 'nxSocket::response'
      connect   : 'nxSocket::connect'
      close     : 'nxSocket::close'
      broadcast : 'nxSocket::broadcast'

  @setUri = (uri) -> config.uri = uri

  getter = (proto, obj) ->
    angular.forEach obj, (fn, key) ->
      proto.__defineGetter__ key, ->
        fn.call proto

  class nxPaket
    constructor: (head, body) ->

  # external nxWebSocket class, `replaces` WebSocket
  class nxWebsocket
    constructor: (options) ->

      @socket         = null
      @ready          = []
      @responses      = {}
      @subscribtions  = {}
      @connected      = false
      @scopes         = []

      options        = angular.extend {}, config, options
      getter @,
        uri     : -> options.uri
        protocol: -> options.protocol
        options : -> options

    ###
      internal send method
    ###
    _send: (head, body) ->
      packet =
        uuid: head.uuid or uuid()
        gid: head.gid or uuid()
        head: head
        body: body
      @_connect (socket) ->
        socket.send JSON.stringify packet


    ###
      nxWebsocket::send

      basic WebSocket send method
      @param packet that will be send through the ws
    ###
    send: (head, body) ->
      if angular.isUndefined body
        body = head
        head = {}
      @_send head, body
    ###
      nxWebsocket::request

      request-response method
      sends data through the socket and evaluates on response
      [@param] mixed data to be send
      @param response $scope or callback
      [@param] config.timeout override
    ###
    request: (data, response, timeout) ->
      if typeof data is 'function' or
        not response or
        not typeof response.$emit is 'function'
          timeout   = response
          response  = data
          data      = null
      timeout = @options.timeout if not timeout
      data    = null if not data

      if typeof response isnt 'function' and
         not isScope response
          throw new Error 'No method to respond'

      id = uuid()
      @responses[id] = response
      head = response: id
      @send head, data

    ###
      nxWebsocket::subscribe - pubsub-plugin

      send a subscribtion messages to the server
      @param channel or list of channels to subscribe to
      @param scope that subscribes, this scope will emit incoming messages
    ###
    subscribe: (channels, $scope) ->
      throw new Error "No $scope for subscribtion" if not isScope $scope
      channels = [channels] if not angular.isArray channels
      angular.forEach channels, (channel) =>
        if @subscribtions.hasOwnProperty channel
          @subscribtions[channel].push $scope
        else
          @subscribtions[channel] = [$scope]
      @send pubsub: subscribe: channels, null

    ###
      nxWebsocket::unsubscribe - pubsub-plugin

      send a unsubscribe message to the server
      @param channel to unsubscribe the scope from
      @param scope that is unsubscribing
    ###
    unsubscribe: (channel, $scope) ->
      return if not @subscribtions.hasOwnProperty channel
      @subscribtions[channel].filter (scope) -> scope.$id is $scope.$id
      @send pubsub: unsubscribe: channel, null

    ###
      nxWebsocket::_emit

      internal emitter to send an event to all connected scopes
      first parameter is the name of the event, other arguments
      will be applied to the $emit method
      @param event
    ###
    _emit: (args...) ->
      angular.forEach @scopes, (scope) ->
        scope.$emit.apply scope, args
        # we need to tell this angular scope that something happend
        scope.$digest()

    ###
      nxWebsocket::_handleResponse

      internal response handler
      will distribute the packets response to the right callbacks/$scopes
      @param packet
    ###
    _handleResponse: (packet) ->
      head = packet.head
      body = packet.body
      return @_emit @options.socket.broadcast, body if not head.response
      response = @responses[head.response]
      return response.call @, body if typeof response is 'function'
      response.$apply =>
        response.$emit @options.socket.emit, body

    _close: (err) ->
      @connected = false
      @socket = null
      @_emit @options.socket.close, err

    ###
      nxWebsocket::_connect

      internal method to be sure that connections are ready
      @param function to be called with live socket connection
    ###
    _connect: (fn) ->
      if not @socket
        socket = new WebSocket @options.uri, @options.protocol
        socket.onopen = =>
          @connected = true
          @_emit @options.socket.connect
          angular.forEach @ready, (fn) ->
            fn.call socket, socket
        socket.onerror = (err) => @_close err
        socket.onclose = => @_close()
        socket.onmessage = (_packet) =>
          return new Error "Missing packet content" if not _packet.hasOwnProperty 'data'
          packet = JSON.parse _packet.data
          @_handleResponse packet

        @socket = socket

      return fn.call @socket, @socket if @socket.readyState is 1
      @ready.push fn

  # Provider API
  # connection method
  connect = (options, protocol) ->
    if typeof options is 'string'
      options = uri: options
    if protocol
      options.protocol = protocol
    new nxWebsocket options

  socket = null
  api =
    connect: connect # to connect a socket
    open: connect # or to open a connection

    send: (args...) -> api.socket.send.apply socket, args
    request: (args...) -> api.socket.request.apply socket, args
    publish: (args...) -> api.socket.publish.apply socket, args
    subscribe: (args...) -> api.socket.subscribe.apply socket, args
    unsubscribe: (args...) -> api.socket.unsubscribe.apply socket, args

  api.__defineGetter__ 'connected', -> api.socket.connected
  api.__defineGetter__ 'socket', ->
    return socket if socket
    return socket = connect config.uri, config.protocol

  @$get = -> api
