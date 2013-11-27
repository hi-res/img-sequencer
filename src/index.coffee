
if exports? and module and module.exports
	Pivot = require 'the-pivot' 

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

		# Scale for retina
		width  = @data.frame.width  * @data.frame.scale
		height = @data.frame.height * @data.frame.scale

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
	

	_resize: =>

		$window = $(window)

		@set_size $window.width(), $window.height()


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


	noload: (@data, @_cache) ->
		@_setup()

		
	###
	Set the playback mode
	###
	set_mode: (mode) =>
		
		# Unset previous events
		@mode?.off 'update', @update
		
		@mode = mode

		# Subscribe to new mode tick
		@mode.on 'update', @update


	set_size: (@width, @height) =>

		@el.style.width  = @width  + 'px'
		@el.style.height = @height + 'px'

		@container.style.width  = @el.style.width
		@container.style.height = @el.style.height

		$frames = $(@container).find @tag_type

		Sequencer.util.resize $frames, @data.frame.width, @data.frame.height, @width, @height, @cssbackgroundsize


	update: => 
		return unless @mode?
		@_update()


	###
	Enable the automatic resizing of the sequencer container on window resize
	###
	enable_automatic_resize: ->
		$(window).on 'resize', @_resize
		@_resize()
		

	###
	Disable the automatic resizing of the sequencer container on window resize
	###
	disable_automatic_resize: ->
		$(window).off 'resize', @_resize


	###
	Return the number of frames in the sequence
	@return [Int]
	###
	get_total_frames: -> @data.total_frames - 1

	destroy: ->			
		@el.innerHTML = ''


# exporting
if exports? and module and module.exports
	module.exports = Sequencer
else if window
	window.Sequencer = Sequencer