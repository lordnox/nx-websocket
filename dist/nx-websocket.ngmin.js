(function () {
  'use strict';
  var NxWebsocket, app, __slice = [].slice;
  app = angular.module('nx');
  app.provider('nxWebsocket', NxWebsocket = function () {
    var api, config, connect, getter, isScope, nxPaket, nxWebsocket, openSockets, socket, uuid;
    openSockets = {};
    uuid = function () {
      return Math.random();
    };
    isScope = function (scope) {
      return typeof scope === 'object' && typeof scope.$emit === 'function';
    };
    config = {
      uri: 'ws://localhost',
      protocol: void 0,
      timeout: 500,
      socket: {
        emit: 'nxSocket::response',
        connect: 'nxSocket::connect',
        close: 'nxSocket::close',
        broadcast: 'nxSocket::broadcast'
      }
    };
    this.setUri = function (uri) {
      return config.uri = uri;
    };
    getter = function (proto, obj) {
      return angular.forEach(obj, function (fn, key) {
        return proto.__defineGetter__(key, function () {
          return fn.call(proto);
        });
      });
    };
    nxPaket = function () {
      function nxPaket(head, body) {
      }
      return nxPaket;
    }();
    nxWebsocket = function () {
      function nxWebsocket(options) {
        this.socket = null;
        this.ready = [];
        this.responses = {};
        this.subscribtions = {};
        this.connected = false;
        this.scopes = [];
        options = angular.extend({}, config, options);
        getter(this, {
          uri: function () {
            return options.uri;
          },
          protocol: function () {
            return options.protocol;
          },
          options: function () {
            return options;
          }
        });
      }
      nxWebsocket.prototype._send = function (head, body) {
        var packet;
        packet = {
          uuid: head.uuid || uuid(),
          gid: head.gid || uuid(),
          head: head,
          body: body
        };
        return this._connect(function (socket) {
          return socket.send(JSON.stringify(packet));
        });
      };
      nxWebsocket.prototype.send = function (head, body) {
        if (angular.isUndefined(body)) {
          body = head;
          head = {};
        }
        return this._send(head, body);
      };
      nxWebsocket.prototype.request = function (data, response, timeout) {
        var head, id;
        if (typeof data === 'function' || !response || !typeof response.$emit === 'function') {
          timeout = response;
          response = data;
          data = null;
        }
        if (!timeout) {
          timeout = this.options.timeout;
        }
        if (!data) {
          data = null;
        }
        if (typeof response !== 'function' && !isScope(response)) {
          throw new Error('No method to respond');
        }
        id = uuid();
        this.responses[id] = response;
        head = { response: id };
        return this.send(head, data);
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
        return this.send({ pubsub: { subscribe: channels } }, null);
      };
      nxWebsocket.prototype.unsubscribe = function (channel, $scope) {
        if (!this.subscribtions.hasOwnProperty(channel)) {
          return;
        }
        this.subscribtions[channel].filter(function (scope) {
          return scope.$id === $scope.$id;
        });
        return this.send({ pubsub: { unsubscribe: channel } }, null);
      };
      nxWebsocket.prototype._emit = function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return angular.forEach(this.scopes, function (scope) {
          scope.$emit.apply(scope, args);
          return scope.$digest();
        });
      };
      nxWebsocket.prototype._handleResponse = function (packet) {
        var body, head, response, _this = this;
        head = packet.head;
        body = packet.body;
        if (!head.response) {
          return this._emit(this.options.socket.broadcast, body);
        }
        response = this.responses[head.response];
        if (typeof response === 'function') {
          return response.call(this, body);
        }
        return response.$apply(function () {
          return response.$emit(_this.options.socket.emit, body);
        });
      };
      nxWebsocket.prototype._close = function (err) {
        this.connected = false;
        this.socket = null;
        return this._emit(this.options.socket.close, err);
      };
      nxWebsocket.prototype._connect = function (fn) {
        var socket, _this = this;
        if (!this.socket) {
          socket = new WebSocket(this.options.uri, this.options.protocol);
          socket.onopen = function () {
            _this.connected = true;
            _this._emit(_this.options.socket.connect);
            return angular.forEach(_this.ready, function (fn) {
              return fn.call(socket, socket);
            });
          };
          socket.onerror = function (err) {
            return _this._close(err);
          };
          socket.onclose = function () {
            return _this._close();
          };
          socket.onmessage = function (_packet) {
            var packet;
            if (!_packet.hasOwnProperty('data')) {
              return new Error('Missing packet content');
            }
            packet = JSON.parse(_packet.data);
            return _this._handleResponse(packet);
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
    connect = function (options, protocol) {
      if (typeof options === 'string') {
        options = { uri: options };
      }
      if (protocol) {
        options.protocol = protocol;
      }
      return new nxWebsocket(options);
    };
    socket = null;
    api = {
      connect: connect,
      open: connect,
      send: function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return api.socket.send.apply(socket, args);
      },
      request: function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return api.socket.request.apply(socket, args);
      },
      publish: function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return api.socket.publish.apply(socket, args);
      },
      subscribe: function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return api.socket.subscribe.apply(socket, args);
      },
      unsubscribe: function () {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return api.socket.unsubscribe.apply(socket, args);
      }
    };
    api.__defineGetter__('connected', function () {
      return api.socket.connected;
    });
    api.__defineGetter__('socket', function () {
      if (socket) {
        return socket;
      }
      return socket = connect(config.uri, config.protocol);
    });
    return this.$get = function () {
      return api;
    };
  });
}.call(this));