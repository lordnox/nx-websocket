
window.createAsyncWebSocketMock = (done, async) ->
  index = 0
  job = null

  window.WebSocket = mock
    readyState: 1
    send: (packet) ->
      packet.pubsub.should.eql job.packet
      next index + 1
  , -> # ignore constructor with readyState = 1

  next = (_index) ->
    index = _index
    return done() if index >= async.length
    job = async[index]
    job.fn()

  next 0