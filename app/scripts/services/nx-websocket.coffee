"use strict"

app = angular.module("nx")

app.provider "nxWebsocket", NxWebsocket = ->

  # hash for all open sockets
  openSockets = {}

  # simple internal uuid method
  uuid = -> Math.random()

  isScope = (scope) ->
    typeof scope is 'object' and typeof scope.$emit is 'function'

  config = 
    uri: 'ws://localhost'
    header: []
    timeout: 500
    socket: 
      emit      : 'nxSocket::response'
      close     : 'nxSocket::close'
      broadcast : 'nxSocket::broadcast'

  @setUri = (uri) -> config.uri = uri

  binder = (obj, method) -> (args...) -> obj[method].apply obj, args

  # external nxWebSocket class, `replaces` WebSocket
  class nxWebsocket
    constructor: (@uri, @header) ->
      @socket = null
      @ready = []
      @responses = {}
      @subscribtions = {}
      @connected = false

    ###
      nxWebsocket::send
      
      basic WebSocket send method
      @param packet that will be send through the ws
    ###
    send: (packet = {}) ->
      packet.uuid = packet.uuid or uuid()
      @_connect (socket) ->
        socket.send JSON.stringify packet

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
          timeout = response 
          response = data
          data = null
      timeout = config.timeout if not timeout
      data = null if not data

      if typeof response isnt 'function' and
         not isScope response
          throw new Error 'No method to respond'

      id = uuid()
      @responses[id] = response
      @send
        response: id
        data: data

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
      @send pubsub: subscribe: channels

    ###
      nxWebsocket::unsubscribe - pubsub-plugin

      send a unsubscribe message to the server
      @param channel to unsubscribe the scope from
      @param scope that is unsubscribing
    ###
    unsubscribe: (channel, $scope) ->      
      return if not @subscribtions.hasOwnProperty channel
      @subscribtions[channel].filter (scope) -> scope.$id is $scope.$id
      @send pubsub: unsubscribe: channel
      
    ###
      nxWebsocket::_handleResponse

      internal response handler
      will distribute the packets response to the right callbacks/$scopes
      @param packet
    ###
    _handleResponse: (packet) ->
      response = @responses[packet.response]
      return response.call @, packet.data if typeof response is 'function'
      response.$apply ->
        response.$emit config.socket.emit, packet.data

    _close: (err) ->
      @connected = false
      @socket = null
      @_emit config.socket.close, err

    ###
      nxWebsocket::_connect

      internal method to be sure that connections are ready
      @param function to be called with live socket connection
    ###
    _connect: (fn) ->
      if not @socket
        socket = new WebSocket @uri, @header
        socket.onopen = => 
          @connected = true
          angular.forEach @ready, (fn) ->          
            fn.call socket, socket
        socket.onerror = (err) => @_close err
        socket.onclose = => @_close()
        socket.onmessage = (_packet) =>
          return new Error "Missing packet content" if not _packet.hasOwnProperty 'data'
          packet = JSON.parse _packet.data
          return if not packet.hasOwnProperty 'data'
          return @_handleResponse packet if packet.response

        @socket = socket

      return fn.call @socket, @socket if @socket.readyState is 1
      @ready.push fn

  # Provider API
  connect = (uri, header) -> new nxWebsocket uri, header
  socket = connect config.uri, config.header
  api =
    socket: socket
    open: connect
    connect: connect

    #send: (args...) -> socket.send.apply socket, args
    #request: (args...) -> socket.request.apply socket, args
    #publish: (args...) -> socket.publish.apply socket, args
    #subscribe: (args...) -> socket.subscribe.apply socket, args
    #unsubscribe: (args...) -> socket.unsubscribe.apply socket, args

    send: binder socket, 'send'
    request: binder socket, 'request'
    publish: binder socket, 'publish'
    subscribe: binder socket, 'subscribe'
    unsubscribe: binder socket, 'unsubscribe'

  api.__defineGetter__ 'connected', -> socket.connected

  @$get = -> api
