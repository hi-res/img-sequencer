
class Sequencer.SpritesheetPlayer extends Pivot

	chrome            : (window.navigator.userAgent.toLowerCase().indexOf( 'chrome' ) > -1)
	el                : null
	current_frame     : -1
	spritesheet_index : -1
	offset_x		  : 0
	offset_y		  : 0
	mode              : null
	cssbackgroundsize : false
	dev               : true
	tag_type          : 'div' # div or img

	log: (args...) =>
		console.debug(args...) if @dev

	constructor: ( el ) ->

		@el = document.getElementById el
		@el.style.overflow = 'hidden'



	###
	Load images from the data
	###
	_load_images: =>

		@_cache      = []
		loaded       = 0
		total_spritesheets = @get_total_spritesheets()

		on_load_complete = (img) =>

			if img.dataset?
				id = img.dataset.frame
			else
				id = img.getAttribute 'data-frame'

			@_cache[id] = img

			if loaded is total_spritesheets
				@_setup()

			loaded++
			

		for frame in [0..total_spritesheets]

			# Use first extension as default
			file_ext = @data.extensions[0]

			# Use webp if chrome and webp is supported
			if @chrome
				for ext in @data.extensions
					file_ext = ext if ext is 'webp'
				
			path = @path + '/' + frame + '.' + file_ext

			loader = new Sequencer.ImageLoader(path, frame)
			loader.on 'complete', on_load_complete


	_create_frame: (src, class_name) ->

		el = document.createElement 'div'
		el.className      = class_name
		el.style.position = 'absolute'
		el.style.width    = '100%'
		el.style.height   = '100%'
		el.style.backgroundImage = "url(#{src})" if src
		el.style.backgroundRepeat = "no-repeat"
		el.style.visibility = 'hidden'

		return el

	###
	Setup the container
	###
	_setup: =>
		# @log 'setup'

		# Create a div for each spritesheet

		@container = document.createElement 'div'
		@container.style.position = 'absolute'
		@el.appendChild @container

		width  = @data.frame.width  * @data.frame.scale
		height = @data.frame.height * @data.frame.scale

		@frame_width = @data.frame.width
		@frame_height = @data.frame.height

		@max_frames_horizontal  = Math.round(@data.width  / @data.frame.width)
		@max_frames_vertical    = Math.round(@data.height / @data.frame.height)

		@_frames = []

		for img, i in @_cache

			el = @_create_frame img.src, 'sd_frame'

			@_frames.push el

			@container.appendChild el

		@_cache = null

		# HD frame
		hd_frame = @_create_frame('', 'hd_frame')
		@container.appendChild hd_frame
		@_hd_frame = $ hd_frame

		@set_size width, height

		@trigger 'setup_complete', @

	_update: (force = false) =>

		# Get the current frame
		frame = @mode.get_frame()

		# @log 'frame', frame

		# Get the current spritesheet
		spritesheet_index = Math.floor frame / @data.frames_per_spritesheet

		frames_at_index = spritesheet_index * @data.frames_per_spritesheet
		
		tile = frame - frames_at_index
		# @log 'spritesheet', spritesheet_index
		# @log 'spritesheet', spritesheet_index, 'tile', tile, 'frame', frame

		# Calculate the actual x/y position on the spritesheet grid
		index = -1
		xpos = 0
		ypos = 0
		for y in [0...@max_frames_vertical]
			for x in [0...@max_frames_horizontal]
				index++
				if index == tile
					xpos = x
					ypos = y
					break

		background_x = -(xpos * @frame_width)
		background_y = -(ypos * @frame_height)

		background_x += @offset_x
		background_y += @offset_y

		if frame isnt @current_frame or force

			@hide_hd_frame()

			# Hide the last image it it exists
			if @_frames[@spritesheet_index]?

				@_frames[@spritesheet_index].style.visibility = 'hidden'
				@_frames[@spritesheet_index].style.zIndex = 0

			@current_frame = frame
			@spritesheet_index = spritesheet_index

			@_frames[spritesheet_index].style.backgroundPositionX = background_x + 'px'
			@_frames[spritesheet_index].style.backgroundPositionY = background_y + 'px'
			@_frames[spritesheet_index].style.visibility = 'visible'
			@_frames[spritesheet_index].style.zIndex = 1



	_resize: =>

		$window = $(window)

		@set_size $window.width(), $window.height()

		@_update(true)


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

		# @log 'set size', @width, @height

		@el.style.width  = '100%'
		@el.style.height = '100%'

		@container.style.width  = @width  + 'px'
		@container.style.height = @height + 'px'

		# @log 'el', @el

		$frames = $(@container).find '.sd_frame'
		hd_frame = $(@container).find '.hd_frame'

		[@frame_width, @frame_height, @offset_x, @offset_y] = Sequencer.util.resize_spritesheet $frames, @data.frame.width, @data.frame.height, @width, @height, @max_frames_horizontal, @max_frames_vertical
		Sequencer.util.resize hd_frame, @data.frame.width, @data.frame.height, @width, @height, true
		# @log 'resized', @frame_width, @frame_height


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
	Show a high quality frame
	@param [Image] img
	###
	show_hd_frame: (img) ->

		src = "url(#{img.src})"
		@_hd_frame.css('background-image', src)

		TweenLite.to @_hd_frame, 0.3, {autoAlpha: 1}
		
		@_hd_frame.css
			'z-index': 10

	###
	Hide the high quality frame
	###
	hide_hd_frame: ->

		TweenLite.killTweensOf @_hd_frame

		@_hd_frame.css
			'visibility': 'hidden'
			'opacity': 0
			'z-index': 0

	###
	Return the number of frames in the sequence
	@return [Int]
	###
	get_total_frames: -> @data.total_frames - 1

	###
	Return the number of frames in the sequence
	@return [Int]
	###
	get_total_spritesheets: -> @data.total_spritesheets - 1

	destroy: ->         
		@el.innerHTML = ''