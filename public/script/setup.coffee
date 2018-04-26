rdio_user = null
electron = window && window.process && window.process.type #true if loading using electron
if (electron)
	{ipcRenderer} = require('electron');

if (electron)
	scope = angular.element($("body")).scope()
	$.get '/sessionID', (sessionID) =>
		ipcRenderer.send('storeSongs', {
			roomID: roomID,
			sessionID: sessionID
		});
	ipcRenderer.on 'localEnabled', (event) =>
		$.post '/' + roomID+ '/enabled', {
			type: 'local',
			roomID: roomID
		}, (err) ->
			if (!err)
				loadPlaylist()


socket = io(window.location.origin)
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)
	if host
		$.post('/host/'+roomID+'/login', {
			roomID: roomID,
			socketID: socket.id
		})

SC.initialize {
    client_id: "3baff77b75f4de090413f7aa542254cd"
}
if (host == true)
	$.post('/' + roomID + '/enabled', {
		type: 'soundcloud',
		roomID: roomID
	})

googleApiClientReady = ->
	gapi.client.setApiKey '#'
	gapi.client.load 'youtube', 'v3'
	if (host == true)
		$.post('/' + roomID+ '/enabled', {
			type: 'youtube',
			roomID: roomID
		}, (err) ->
			loadPlaylist() if !err)

if (host == true)
	#youtube stuff
	tag = document.createElement('script')
	tag.src = "https://www.youtube.com/iframe_api"
	firstScriptTag = document.getElementsByTagName('script')[0]
	firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

	#rdio stuff
	rdio_player = null;
	$.ajax {
		url: '/rdio/playbackToken',
		success: (res) ->
			flashvars = {
				'playbackToken': res,
				'domain': window.location.hostname,
				'listener': 'rdioCallback'    # the global name of the object that will receive callbacks from the SWF
			}
			params = {
				'allowScriptAccess': 'always'
			}
			swfobject.embedSWF('/rdio-api.swf', 'rdio_player', 1, 1, '9.0.0', 'expressInstall.swf', flashvars, params, {})
	}

	#SC2 stuff
	soundManager.setup({
		url: '/script/soundmanager2/swf/'
	})


rdioCallback = {
	ready: (user) ->
		rdio_player = $('#rdio_player').get(0)
		$.post('/' + roomID+ '/enabled', {
			type: 'rdio',
			roomID: roomID
		}, (err) ->
			if !err
				rdio_user = user
				loadPlaylist())
	positionChanged: (position) ->
		scope = angular.element($("body")).scope()
		setPostion = () -> scope.playlist.positionChanged "rdio", position
		if (scope.$$phase || scope.$root.$$phase) then setPostion() else scope.$apply(setPostion)
	playStateChanged: (playState) ->
		scope = angular.element($("body")).scope()
		setPlayState = ()->
			if (playState == 2)
				scope.playlist.state = 0
			else if (playState == 1)
				scope.playlist.state = 1
			else if (playState == 0 || playState == 4)
				scope.playlist.state = 2
			else if (playState == 3)
				scope.playlist.state = 3
		if (scope.$$phase || scope.$root.$$phase) then setPlayState() else scope.$apply(setPlayState)
	playingTrackChanged: (playingTrack, sourcePosition) ->
		scope = angular.element($("body")).scope()
		playlist = scope.playlist
		if (playlist.autoplay)
			song_details = search.cleanUpResults({collection: [playingTrack]}, 'rdio').collections[0]
			playlist.autoplay = song_details
			playlist.loadArt()
			playlist.save 'autoplay', JSON.stringify(song_details)
			if (!scope.$$phase && !scope.$root.$$phase)
				scope.$apply()
}

window.onunload = () ->
	sessionStorage.clear()

logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    false
