
if exports? and module and module.exports
	Pivot = require 'the-pivot' 

window?.requestAnimFrame = (->
	window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
		window.setTimeout callback, 1000 / 60
)()

Sequencer = Sequencer or {}

class Sequencer.ImageLoader extends Pivot

	constructor: (path, frame) ->

		img = new Image()

		img.src = path

		if img.dataset?
			img.dataset.frame = frame 
		else
			img.setAttribute('data-frame', frame)

		img.onload = =>
			@trigger 'complete', img


class Sequencer.Player extends Pivot

	pixel_ratio       : window.devicePixelRatio
	retina            : window.devicePixelRatio is 2
	chrome 		      : (window.navigator.userAgent.toLowerCase().indexOf( 'chrome' ) > -1)
	el                : null
	current_frame     : true
	mode 			  : null
	cssbackgroundsize : false
	dev 			  : true
	tag_type          : 'div' # div or img

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

		@_cache 	 = []
		loaded  	 = 0
		total_frames = @get_total_frames()

		on_load_complete = (img) =>

			if img.dataset?
				id = img.dataset.frame
			else
				id = img.getAttribute 'data-frame'

			@_cache[id] = img

			if loaded is total_frames
				@_setup()

			loaded++
			

		for frame in [0..total_frames]

			# Use first extension as default
			file_ext = @data.extensions[0]

			# Use webp if chrome and webp is supported
			if @chrome
				for ext in @data.extensions
					file_ext = ext if ext is 'webp'
				
			path = @path + '/' + frame + '.' + file_ext

			loader = new Sequencer.ImageLoader(path, frame)
			loader.on 'complete', on_load_complete

	###
	Setup the container
	###
	_setup: =>

		scale  = (if @retina is true then 0.5 else 1)

		# Scale for retina
		width  = @data.frame.width  * scale
		height = @data.frame.height * scale

		@_frames = []

		for img, i in @_cache

			if @cssbackgroundsize

				el = document.createElement 'div'
				el.style.position = 'absolute'
				el.style.width    = '100%'
				el.style.height   = '100%'
				el.style.backgroundImage = "url(#{img.src})"
				el.style.backgroundRepeat = "no-repeat"
				el.style.visibility = 'hidden'

			else

				img.style.position   = 'absolute'
				img.style.width      = '100%'
				img.style.height     = '100%'
				img.style.visibility = 'hidden'

				@tag_type = 'img'

				el = img

			@_frames.push el

			@container.appendChild el

		@_cache = null

		@set_size width, height

		@trigger 'setup_complete', @


	_update: =>

		# Get the current frame
		frame = @mode.get_frame()

		if frame isnt @current_frame

			# Hide the last image it it exists
			if @_frames[@current_frame]?

				@_frames[@current_frame].style.visibility = 'hidden'
				@_frames[@current_frame].style.zIndex = 0

			@current_frame = frame

			@_frames[@current_frame].style.visibility = 'visible'
			@_frames[@current_frame].style.zIndex = 1
	


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
				@data = JSON.parse data.responseText
				@_load_images() 
			error: (error) => 
				#@log error


	noload: (@data, frames) ->

		#@data = data.
		@_cache = []

		for img, i in frames.images
			@_cache[i] = img.tag

		@_setup()


	###
	Start playback on the current mode
	###
	play: => 

		unless @mode?
			console.warn 'Error --> Set a playback mode first'
		else
			#@log 'play'
			@on 'tick', @tick
		

	###
	Stop playback on the current mode
	###
	stop: => 

		#@log 'stop'
		@off 'tick', @tick
		
	###
	Set the playback mode
	###
	set_mode: (mode) =>
		
		# Unset previous events
		@mode?.off 'complete', @stop
		
		@mode = mode

		#@log 'setting mode -->', @mode.id

		# Add new events
		@mode.on 'complete', @stop


	set_size: (@width, @height) =>

		@el.style.width  = @width  + 'px'
		@el.style.height = @height + 'px'

		@container.style.width  = @el.style.width
		@container.style.height = @el.style.height

		$frames = $(@container).find @tag_type

		Utils.resize $frames, @data.frame.width, @data.frame.height, @width, @height, @cssbackgroundsize


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

	destroy: ->

		@stop()

		@el.innerHTML = ''



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
	speed: 1

	constructor: (@data) ->

	update: -> @_set_frame()

	_set_frame: ->

		if @frame >= @data.total_frames - 1
			@trigger 'complete'
		else
			@frame += @speed

	get_frame: -> Math.floor @frame


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
		
		@frame += @speed

	get_frame: -> Math.floor @frame


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

	get_frame: -> Math.floor @frame

###----------------------------------------------
Utils
###

Utils = 

	calculate_resize: (image_width, image_height, win_width, win_height, backgroundsize) ->

		window_ratio = win_width / win_height
		image_ratio1 = image_width / image_height
		image_ratio2 = image_height / image_width

		if window_ratio < image_ratio1
			# log 'portrait'
			new_height = win_height
			new_width  = new_height * image_ratio1

			new_top  = 0
			new_left = (win_width * .5) - (new_width * .5) 

		else
			# log 'landscape'
			new_width  = win_width
			new_height = new_width * image_ratio2

			new_top  = (win_height * .5) - (new_height * .5)
			new_left = 0 

		return {
			x      : new_left
			y      : new_top
			width  : new_width
			height : new_height
		}

	###
	Resize image(s) to the browser size retaining aspect ratio
	@param [jQuery]  $images
	@param [Number]  image_width
	@param [Number]  image_height
	@param [Number]  win_width
	@param [Number]  win_width
	@param [Boolean] backgroundsize
	###
	resize: ($images, image_width, image_height, win_width, win_height, backgroundsize) ->

		data = @calculate_resize image_width, image_height, win_width, win_height, backgroundsize

		# Background size is a lot fast than scaling and positioning an image

		if backgroundsize
			$images.css
				'background-size'     : "#{data.width}px #{data.height}px"
				'background-position' : "#{data.x}px #{data.y}px"
		else
			$images.css
				'margin-top'  : "#{data.y}px"
				'margin-left' : "#{data.x}px"
				'width'       : "#{data.width}px"
				'height'      : "#{data.height}px"


# exporting
if exports? and module and module.exports
	module.exports = Sequencer
else if window
	window.Sequencer = Sequencer