
window.createAsyncWebSocketMock = (done, async) ->
  index = 0
  job = null

  window.WebSocket = mock
    readyState: 1
    send: (packet) ->
      packet = JSON.parse packet
      packet.head.should.eql job.head if job.head
      packet.body.should.eql job.body if job.body
      next index + 1
  , -> # ignore constructor with readyState = 1

  next = (_index) ->
    index = _index
    return done() if index >= async.length
    job = async[index]
    job.fn()

  next 0