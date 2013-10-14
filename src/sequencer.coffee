window.requestAnimFrame = (->
	window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
		window.setTimeout callback, 1000 / 60
)()


Sequencer = Sequencer or {}

class Sequencer.ImageLoader

	constructor: (path, frame, callback) ->

		img = new Image()

		img.src = path
		img.dataset.frame = frame 

		img.onload = =>
			callback img


class Sequencer.Player extends Pivot

	pixel_ratio     : window.devicePixelRatio
	retina          : window.devicePixelRatio is 2
	chrome 		    : (navigator.userAgent.toLowerCase().indexOf( 'chrome' ) > -1)
	el              : null
	current_frame   : null
	mode 			: null
	dev 			: true

	log: (args...) =>
		console.log(args...) if @dev

	constructor: ( el ) ->

		@el = document.getElementById el

		@container = document.createElement 'div'
		@container.style.position = 'absolute'
		@el.appendChild @container

		(animloop = =>
			window.requestAnimFrame animloop
			
			@trigger 'tick'
		)()
		

	###
	Load images from the data
	###
	_load_images: =>

		@_cache  = []

		counter = 0
		total_frames = @data.total_frames

		on_load_complete = (img) =>

			counter++

			if counter is total_frames
				@_setup()

			@_cache[img.dataset.frame] = img
		
		for frame in [0...total_frames]

			# Use webp if chrome and webp is supported
			if @chrome
				for ext in @data.extensions
					file_ext = ext if ext is 'webp'
			else
				# Use first extension
				file_ext = @data.extensions[0]

			path = @path + '/' + frame + '.' + file_ext

			loader = new Sequencer.ImageLoader(path, frame, on_load_complete)

	###
	Setup the container
	###
	_setup: =>

		scale  = (if @retina is true then 0.5 else 1)

		# Scale for retina
		@width  = @data.frame.width  * scale
		@height = @data.frame.height * scale

		# If the image needs scaling
		@width  *= @data.frame.scale
		@height *= @data.frame.scale

		@el.style.width  = @width  + 'px'
		@el.style.height = @height + 'px'

		@container.style.width  = @el.style.width
		@container.style.height = @el.style.height

		for img in @_cache

			img.style.position   = 'absolute'
			img.style.width      = '100%'
			img.style.height     = '100%'

			@container.appendChild img


		@trigger 'setup_complete'



	_update: =>

		# Get the current frame
		frame = @mode.get_frame()

		if frame isnt @current_frame

			# Hide the last image it it exists
			if @_cache[@current_frame]?
				@_cache[@current_frame].style.visibility = 'hidden'
				@_cache[@current_frame].style.zIndex = 0

			@current_frame = frame

			@_cache[@current_frame].style.visibility = 'visible'
			@_cache[@current_frame].style.zIndex = 1
	


	###
	Validate the new frame
	@return [Int]
	###
	_validate_frame: ->

		frame = @mode.get_frame()

		if frame < 0
			@_frame = 0
			console.warn 'Frame is less than 0'
			@stop()
		else if frame > @get_total_frames()
			@_frame = @get_total_frames()
			console.warn "Frame is greater than total frames, stopping at #{@get_total_frames()}"
			@stop()

	###----------------------------------------------
	@public
	###

	load: (@path, frames) =>

		$.ajax
			url: @path + '/' + frames,
			complete: (data) =>
				@data = data.responseJSON
				@_load_images() 
			error: (error) => 
				@log error

	###
	Start playback on the current mode
	###
	play: => 

		unless @mode?
			console.warn 'Error --> Set a playback mode first'
		else
			@log 'play'
			@on 'tick', @tick
		

	###
	Stop playback on the current mode
	###
	stop: => 

		@log 'stop'
		@off 'tick', @tick
		
	###
	Set the playback mode
	###
	set_mode: (mode) =>
		
		# Unset previous events
		@mode?.off 'complete', @stop
		
		@mode = mode

		@log 'setting mode -->', @mode.id

		# Add new events
		@mode.on 'complete', @stop


	set_frame: (frame) =>


	tick: => 
		@mode.update()
		@_validate_frame()
		@_update()


	###
	Return the number of frames in the sequence
	@return [Int]
	###
	get_total_frames: -> @data.total_frames - 1




###----------------------------------------------
Playback modes
###


###
Frame mode

Manually set the frame of the sequence
###
class Sequencer.FrameMode extends Pivot

	id: 'FrameMode'
	frame: 0

	constructor: (@data) ->

	update: ->

	set_frame: (@frame) ->

	get_frame: -> @frame


###
Linear mode

Repeats the animation from frame 0 once it reaches the end
###
class Sequencer.LinearMode extends Pivot

	id: 'Linear'
	frame: 0

	constructor: (@data) ->

	update: -> @_set_frame()

	_set_frame: ->

		if @frame >= @data.total_frames - 1
			@trigger 'complete'
		else
			@frame++

	get_frame: -> @frame


###
RepeatMode

Repeats the animation from frame 0 once it reaches the end
###
class Sequencer.RepeatMode extends Pivot

	id: 'Repeat'
	frame: 0
	speed: 1

	constructor: (@data) ->

	update: -> @_set_frame()

	_set_frame: ->

		if @frame >= @data.total_frames - 1
			@frame = 0
		
		@frame++

	get_frame: -> @frame


###
ReverseMode

Plays the animation back and forth
###
class Sequencer.ReverseMode extends Pivot

	id: 'Reverse'
	frame: 0
	speed: 1

	constructor: (@data) ->

	update: -> @_set_frame()

	_set_frame: ->

		if @frame >= @data.total_frames - 1
			@frame = -Math.abs @speed

		if @frame <= 0
			Math.abs @speed
		
		@frame += @speed

	get_frame: -> @frame


# exporting
if exports? and module and module.exports
	exports.Sequencer = Sequencer
else if window
	window.Sequencer = Sequencer