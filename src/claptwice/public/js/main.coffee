class Microphone
	constructor: (config=null) ->
		@active = false
		@audioContext = new AudioContext()
		@audioRecorder
		@config = $.extend({
				errorHandler: () -> {}
				clipAnalysisHandler: () -> {}
			}, config)
		return

	start: () =>
		navigator.getUserMedia { audio: true }, @capture, (e) =>
			if e.name == 'PERMISSION_DENIED'
				@config.errorHandler('You must allow access to your microphone.')
			else
				@config.errorHandler('We couldn\'t access your microphone.')
	
	capture: (stream) =>
		@active = true
		inputPoint = @audioContext.createGain()
		realAudioInput = @audioContext.createMediaStreamSource(stream)
		audioInput = realAudioInput
		audioInput.connect(inputPoint)
		@audioRecorder = new Recorder(inputPoint, {
				workerPath: '/public/js/vendor/recorderWorker.js'
			})
		@audioRecorder.clear()
		@audioRecorder.record()
		zeroGain = @audioContext.createGain()
		zeroGain.gain.value = 0.0
		inputPoint.connect(zeroGain)
		zeroGain.connect(@audioContext.destination)
	
	save: () =>
		@audioRecorder.exportWAV (blob) =>
			@config.clipAnalysisHandler(blob)
			@audioRecorder.clear()

class App
	constructor: (config=null) ->
		@config = $.extend({
				selectors: {
					error: '#error'
				}
				endpoints: {
					analyze: '/analyze'
				}
			}, config)
		
		@microphone = new Microphone { errorHandler: @showError, clipAnalysisHandler: @analyzeClip }
		@ready()
		@bind()

	ready: () =>
		navigator.getUserMedia = navigator.webkitGetUserMedia || navigator.mozGetUserMedia

		if @config['rdio_token']
			R.accessToken(@config['rdio_token'])

	bind: () =>
		_this = @

		$('#start').on 'click', (e) =>
			@microphone.start()
			return false

		$('#export').on 'click', (e) =>
			@microphone.save()
			return false
	
	analyzeClip: (blob) =>
		reader = new FileReader()
		console.log blob
		reader.addEventListener 'loadend', () =>
			$.post @config.endpoints.analyze, { blob: reader.result }, (data) ->
				console.log data
		reader.readAsBinaryString(blob)

	showError: (message=null) =>
		$error = $(@config.selectors.error)

		if message
			$error.text(message).slideDown()
		else
			$error.slideUp()

window.claptwice = new App(window.claptwice?.config ? {})

$(document).ready ->
	window.claptwice.ready()
