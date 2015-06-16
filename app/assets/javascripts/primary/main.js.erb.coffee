@app = angular.module('CloudNet', ['ngResource', 'angularMoment', 'ngRoute', 'ngAnimate', 'ui.unique'])

@app.config(['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->
  $locationProvider.html5Mode({enabled: true, requireBase: false})
  $routeProvider.when('/post', { redirectTo: '/search' } )
  #$routeProvider.when('/search', { templateUrl: "<%= asset_path('templates/location.html') %>"} )
])

inactive_pin  = "<%= asset_path('pins/inactive-pin.png') %>"
active_pin    = "<%= asset_path('pins/active-pin.png') %>"
budget_pin    = "<%= asset_path('pins/budget-pin.png') %>"
mapbox_key    = "<%= KEYS[:mapbox][:token] %>"
mapboxPublicToken = "<%= KEYS[:mapbox][:public_token] %>"
movie_path    = "<%= asset_path('ZeroClipboard.swf') %>"
@helpers ?= {}
@models ?= {}

ZeroClipboard.config
  trustedDomains: [window.location.host]
  moviePath: movie_path
  cacheBust: false

# This Directive allows you to have a Sticky Dropdown where a dropdown stays open
# even if the data is completely changed. It does this by reading the unique ID 
# associated with the dropdown and then reopening it when the data is refreshed
# It binds to each dropdown element to listen to events to determine which 
# dropdown was opened or closed at any given time
@app.directive 'stickyDropdown', ->
  restrict: "AEC", 
  link: (scope, element, attrs) ->
    $(element).on
      'show.bs.dropdown': -> 
        scope.$parent.openMenuItem = attrs["id"]
      'hide.bs.dropdown': ->
        scope.$parent.openMenuItem = undefined

    if attrs["id"] == scope.$parent.openMenuItem
      $(element).find('[data-toggle="dropdown"]').dropdown('toggle')

    return

@app.directive 'scrollable', ->
  restrict: "AEC", 
  link: (scope, element, attrs) ->
    $(element).perfectScrollbar()

    return

@app.directive 'copyPassword', ->
  restrict: "AEC",
  link: (scope, element, attrs) ->
    client = new ZeroClipboard $(element)
    $(element).tooltip
      trigger:  'focus'
      animation: true
    client.on 'complete', (client, args) ->
      $(element).tooltip('show')

    $(element).on 'shown.bs.tooltip', ->
      setTimeout(->
         $(element).tooltip('hide') 
      , 1000)


@app.directive 'obfuscate', ->
  restrict: "AEC", 
  link: (scope, element, attrs) ->
    $el         = $(element)
    obfuscate   = attrs.obfuscate
    options     = $el.data()
    timeLimit   = options?.timeLimit || 1000
    timeout     = undefined

    $el.click (e) ->
      $el.text(obfuscate)
      $el.addClass('revealed')

    $el.parent().parent().mouseover (e) ->
      window.clearTimeout(timeout) if timeout

    $el.parent().parent().mouseout (e) ->
      unless options.timer is no
        timeout = setTimeout(->
          $el.text(options.message)
          $el.removeClass('revealed')
        , timeLimit)

    return

@app.directive 'locatePresence', ->
  restrict: "AEC",
  link: (scope, element, attrs) ->
    setupMap = (location) ->
      LatLng = [parseFloat(location.latitude), parseFloat(location.longitude)]
      map = L.mapbox.map('jg-map', mapbox_key,
          accessToken: mapboxPublicToken,
          zoomControl: false
          dragging:    false
          doubleClickZoom: false
          touchZoom: false
          scrollWheelZoom: false
          boxZoom:  false
          tap:  false
        ).setView(LatLng, 5)

      marker = L.marker LatLng,
        icon: L.icon
          iconUrl: active_pin
          iconSize: ['26', '32']
          iconAnchor: ['10', '12']
          popupAnchor: [-2, -35]

      marker.addTo(map)

    location = JSON.parse attrs.locatePresence
    setupMap(location)

# This filter is meant to titleize a given input. It turns a string like 
# 'reboot_virtual_machine' into a more readable 'Reboot Virtual Machine'
@app.filter 'actionTitleize', ->
  (input) ->
    return input.split('_').join(' ').replace /\w\S*/g, (word) ->  
      return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase()

@app.filter 'absoluteDate', ->
  (input) ->
    date = new Date(input)
    return date.toUTCString()

@app.filter 'startFrom', ->
  (input, start) ->
    start = +start;
    input.slice start if input