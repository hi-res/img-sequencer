Sequencer = Sequencer or {}

class Sequencer.FrameMode extends Pivot

	id: 'FrameMode'
	frame: 0

	constructor: (@data) ->

	update: ->

	set_frame: (@frame) ->

	get_frame: -> @frame

	total_frames: -> @data.total_frames - 1


class Sequencer.LinearMode extends Pivot

	id: 'Linear'
	frame: 0

	constructor: (@data) ->

	play: (duration = 1, end_frame = 1, ease = Linear.easeNone) ->

		params =
			frame: end_frame
			onUpdate: @_update
			onComplete: @_complete
			ease : ease

		@tween = TweenLite.to @, duration, params

	stop: ->
		TweenLite.killTweensOf(@tween)

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

class Sequencer.RepeatMode extends Pivot

	id: 'Linear'
	frame: 0
	repeat: 1

	constructor: (@data) ->

	play: (@duration = 1, @ease = Linear.easeNone) =>

		params =
			frame: @total_frames()
			onUpdate: @_update
			onComplete: @_complete
			ease : @ease
			repeat: @repeat

		TweenMax.to @, @duration, params

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

	_reverse_complete: => 
		@trigger 'reverse_complete'

		@tween.play()


