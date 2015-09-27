class WiFiData
  constructor: ->
    @netNames = []
    @netdata = {}
    @getData()


  # separate data in chunks divided by ssid
  initprocess: ->
    nd = @netdata
    @data.forEach (a) ->
      if not nd.hasOwnProperty(a["ssid"])
        nd[a["ssid"]] = []
      nd[a["ssid"]].push(a)


  putNetNames: ->
    nets = []
    @data.forEach (net) ->
      if not (nets.indexOf(net["ssid"]) > -1)
        # geht noch nicht
        nets.push(net["ssid"])
    @netNames = nets
    return


  # daten aller netzwerke zusammen
  getAll: ->
    data = []
    _this = @
    # alle messdaten zusammenwerfen
    @netNames.forEach (net) ->
      _this.netdata[net].forEach (value)->
        data.push(value)
    return data

  # alle ssid netzwerknamen
  getNetNames: ->
    @netNames

  # daten eines netzes
  getNet: (net) ->
    @netdata[net]

  # alle daten nach netzen geordnet
  getLoggings: ->
    @netdata

  # daten vom server holen
  # TODO mit paramentern für ssid spezifisches und boundingboxes
  getData: ->
    _this = @
    #$.ajax "data/wifilog.json", (data) ->
    #  _this.data = data
    #  _this.initprocess()
    #  _this.putNetNames()
    url = 'data/wifilog.json'
    $.ajax {
      type: 'GET',
      url: url,
      dataType: 'json',
      async: false,
      data: {}
      success: (data) ->
        _this.data = data
        _this.initprocess()
        _this.putNetNames()

    }

##
# klasse für die eigentliche heatmap
class HMMap
  constructor: (@wlandata)->
    @initmap()
    @setHeatMap(@wlandata)
    return

  # heatmap initialisieren
  setHeatMap: (@wlandata) ->
    hmConfig = {
      max: -50,
      min: -99,
      data: @wlandata
    }
    @heatmapLayer.setData(hmConfig)
    return

  # parameter setzen
  initmap: (myheatmapdata) ->
    @baseLayer = L.tileLayer(
      'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
        attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
        maxZoom: 18,
      }
    )


    cfg = {
      # radius should be small ONLY if scaleRadius is true (or small radius is intended)
      "radius": 35,
      "maxOpacity": .8,
      # scales the radius based on map zoom
      "scaleRadius": false,
      # if set to false the heatmap uses the global maximum for colorization
      # if activated: uses the data maximum within the current map boundaries
      #   (there will always be a red spot with useLocalExtremas true)
      "useLocalExtrema": true,
      # which field name in your data represents the latitude - default "lat"
      latField: 'lat',
      # which field name in your data represents the longitude - default "lng"
      lngField: 'lon',
      # which field name in your data represents the data value - default "value"
      valueField: 'rssi',
      blur: 1
    }
    @heatmapLayer = new HeatmapOverlay(cfg)
    @map = new L.Map('map-canvas', {
      center: new L.LatLng(51.07642,13.0121),
      zoom: 17,
      layers: [@baseLayer, @heatmapLayer]
    })
    return

# karte mit fenster und auswahlselect
class HMSite
  constructor: ->
    @initializeHeatMap()
    @setupNetSelectCB()

  # karte initialisieren
  initializeHeatMap: ->
    @logging =  new WiFiData()
    window.wlanmap = @hmap = new HMMap(@logging.getLoggings())
    @fillSelect()

  # select füllen
  fillSelect: ->
    networks = @logging.netNames
    # only if there are more than one ssid
    if networks.length > 1
      $(".wlanselect").append "<option value=\"all\">Alle</option>"

    networks.forEach (netName) ->
      $(".wlanselect").append "<option value=\"#{netName}\">#{netName}</option>"

  # callback wenn das select geändert wurde
  setupNetSelectCB: ->
    _this = @

    $('.wlanselect').on 'change', (event)->
      key = $('.wlanselect option:selected').val()
      if key == 'all'
        _this.hmap.setHeatMap(_this.logging.getAll())
      else
        _this.hmap.setHeatMap(_this.logging.getNet(key))
      return

    key = $('.wlanselect option:first').val()
    @hmap.setHeatMap(@logging.getAll)
    return


window.onload = ->
  new HMSite
