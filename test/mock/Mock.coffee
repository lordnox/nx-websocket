
window.mock = (prototype, constructor = ->) ->
  klass = (args...) ->
    angular.forEach prototype, (fn, prop) =>
      @[prop] = fn
    constructor.apply @, args

  klass
