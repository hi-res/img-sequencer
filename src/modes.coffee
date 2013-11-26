Sequencer = Sequencer or {}

class Sequencer.FrameMode extends Pivot

	id: 'FrameMode'
	frame: 0

	constructor: (@data) ->

	update: ->

	set_frame: (@frame) ->

	get_frame: -> @frame


class Sequencer.LinearMode extends Pivot

	id: 'Linear'
	frame: 0

	constructor: (@data) ->

	play: (duration = 1, ease = Linear.easeNone) ->

		params =
			frame: @total_frames()
			onUpdate: @_update
			onComplete: @_complete
			ease : ease

		TweenLite.to @, duration, params

	stop: ->
		TweenLite.killTweensOf(@)

	get_frame: => 
		frame = Math.floor @frame

		if frame < 0
			frame = 0
		else if frame > @total_frames()
			frame = @total_frames()

		frame

	total_frames: -> @data.total_frames - 1

	_update: => 
		@trigger 'update'

	_complete: => 
		@trigger 'complete'