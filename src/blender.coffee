
class Sequencer.Blender extends Pivot

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

		percent = frame / @get_total_frames()
		percent = Number percent.toFixed(2)

		for i in [0..@get_total_frames()]

			position = i * (1 / @get_total_frames())

			# normalise percent 
			dx = percent - position
			distance = Math.sqrt dx * dx

			if distance <= 0.1

				normalise = distance * 10

				# Inverse
				opacity = 1 - normalise

				@_frames[i].style.visibility = 'visible'
				@_frames[i].style.zIndex = 1
				@_frames[i].style.opacity = opacity
			else
				@_frames[i].style.visibility = 'hidden'
				@_frames[i].style.zIndex = 0


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
	Set the playback mode
	###
	set_mode: (mode) =>
		
		# Unset previous events
		@mode?.off 'complete', @stop
		
		@mode = mode

		@log 'setting mode -->', @mode.id

		# Add new events
		@mode.on 'complete', @stop


	set_size: (@width, @height) =>

		@el.style.width  = @width  + 'px'
		@el.style.height = @height + 'px'

		@container.style.width  = @el.style.width
		@container.style.height = @el.style.height

		$frames = $(@container).find @tag_type

		Utils.resize $frames, @data.frame.width, @data.frame.height, @width, @height, @cssbackgroundsize


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
