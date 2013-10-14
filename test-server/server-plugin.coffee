
require 'colors'

rand = Math.random()

console.log "plugin loaded".green
console.log "seed: #{rand}".green

module.exports = (req, res, next) ->
	#console.log "plugin used more".red
	#console.log "seed: #{rand}".red
	next();