(function () {
  'use strict';
  var NxWebsocket, app, __slice = [].slice;
  app = angular.module('nxWebsocketApp');
  app.provider('nxWebsocket', NxWebsocket = function () {
    var binder, config, isScope, nxWebsocket, openSockets, uuid;
    openSockets = {};
    uuid = function () {
      return Math.random();
    };
    isScope = function (scope) {
      return typeof scope === 'object' && typeof scope.$emit === 'function';
    };
    config = {
      uri: 'ws://localhost',
      header: [],
      timeout: 500,
      socket: { emit: 'nxSocket::response' }
    };
    binder = function (obj, method) {
      return function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return obj[method].apply(obj, args);
      };
    };
    nxWebsocket = function () {
      function nxWebsocket(uri, header) {
        this.uri = uri;
        this.header = header;
        this.socket = null;
        this.ready = [];
        this.responses = {};
        this.subscribtions = {};
      }
      nxWebsocket.prototype.send = function (packet) {
        if (packet == null) {
          packet = {};
        }
        packet.uuid = packet.uuid || uuid();
        return this._connect(function (socket) {
          return socket.send(packet);
        });
      };
      nxWebsocket.prototype.request = function (data, response, timeout) {
        var id;
        if (typeof data === 'function' || !response || !typeof response.$emit === 'function') {
          timeout = response;
          response = data;
          data = null;
        }
        if (!timeout) {
          timeout = config.timeout;
        }
        if (!data) {
          data = null;
        }
        if (typeof response !== 'function' && !isScope(response)) {
          throw new Error('No method to respond');
        }
        id = uuid();
        this.responses[id] = response;
        return this.send({
          response: id,
          data: data
        });
      };
      nxWebsocket.prototype.subscribe = function (channels, $scope) {
        var _this = this;
        if (!isScope($scope)) {
          throw new Error('No $scope for subscribtion');
        }
        if (!angular.isArray(channels)) {
          channels = [channels];
        }
        angular.forEach(channels, function (channel) {
          if (_this.subscribtions.hasOwnProperty(channel)) {
            return _this.subscribtions[channel].push($scope);
          } else {
            return _this.subscribtions[channel] = [$scope];
          }
        });
        return this.send({ pubsub: { subscribe: channels } });
      };
      nxWebsocket.prototype.unsubscribe = function (channel, $scope) {
        if (!this.subscribtions.hasOwnProperty(channel)) {
          return;
        }
        this.subscribtions[channel].filter(function (scope) {
          return scope.$id === $scope.$id;
        });
        return this.send({ pubsub: { unsubscribe: channel } });
      };
      nxWebsocket.prototype._handleResponse = function (packet) {
        var response;
        response = this.responses[packet.response];
        if (typeof response === 'function') {
          return response.call(this, packet.data);
        }
        return response.$emit(config.socket.emit, packet.data);
      };
      nxWebsocket.prototype._connect = function (fn) {
        var socket, _this = this;
        if (!this.socket) {
          socket = new WebSocket(this.uri, this.header);
          socket.onopen = function () {
            return angular.forEach(_this.ready, function (fn) {
              return fn.call(socket, socket);
            });
          };
          socket.onerror = function () {
          };
          socket.onclose = function () {
          };
          socket.onmessage = function (packet) {
            if (!packet.hasOwnProperty('data')) {
              return;
            }
            if (packet.response) {
              return _this._handleResponse(packet);
            }
          };
          this.socket = socket;
        }
        if (this.socket.readyState === 1) {
          return fn.call(this.socket, this.socket);
        }
        return this.ready.push(fn);
      };
      return nxWebsocket;
    }();
    return this.$get = function () {
      var connect, socket;
      connect = function (uri, header) {
        return new nxWebsocket(uri, header);
      };
      socket = connect(config.uri, config.header);
      return {
        socket: socket,
        open: connect,
        connect: connect,
        send: binder(socket, 'send'),
        request: binder(socket, 'request'),
        publish: binder(socket, 'publish'),
        subscribe: binder(socket, 'subscribe'),
        unsubscribe: binder(socket, 'unsubscribe')
      };
    };
  });
}.call(this));