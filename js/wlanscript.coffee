class WiFiData
  constructor: (@data) ->
    @parse(@data)

  parse: (data) ->
    csvparsed = Papa.parse(data).data
    @wlandata = @groupBy(csvparsed)

  groupBy: (inputArr) ->
    items = {}
    _this = this

    $.each inputArr, (index, val) ->
      key = val[11]
      if key
        if(!items[key])
          items[key] = []

        # bssid, ssid, rssi, lat, lon
        items[String(key)].push(_this.formatData(val))
        return

    return items

  formatData: (val) ->
    net = {
      bssid: val[12],
      ssid: val[11],
      count: parseInt(val[13]) ,
      lat: val[4],
      lng: val[5]
    }

class HMMap
  constructor: (@wlandata)->
    @initmap()
    return

  setHeatMap: (key) ->
    hmConfig = {
      max: -50,
      min: -99,
      data: @wlandata[key]
    }
    @heatmapLayer.setData(hmConfig)
    return

  initmap: (myheatmapdata) ->
    @baseLayer = L.tileLayer(
      'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
        attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
        maxZoom: 18,
      }
    )


    cfg = {
      # radius should be small ONLY if scaleRadius is true (or small radius is intended)
      "radius": 15,
      "maxOpacity": .8,
      # scales the radius based on map zoom
      "scaleRadius": false,
      # if set to false the heatmap uses the global maximum for colorization
      # if activated: uses the data maximum within the current map boundaries
      #   (there will always be a red spot with useLocalExtremas true)
      "useLocalExtrema": false,
      # which field name in your data represents the latitude - default "lat"
      latField: 'lat',
      # which field name in your data represents the longitude - default "lng"
      lngField: 'lng',
      # which field name in your data represents the data value - default "value"
      valueField: 'count',
      blur: 1
    }
    @heatmapLayer = new HeatmapOverlay(cfg)
    @map = new L.Map('map-canvas', {
      center: new L.LatLng(51.07642,13.0121),
      zoom: 17,
      layers: [@baseLayer, @heatmapLayer]
    })
    return


window.onload = ->
  $.get "./wifilog.csv", (data) ->
    netdata = new WiFiData(data)
    $.each netdata.wlandata, (key,value) ->
      $(".wlanselect").append("<option value=\""+key+ "\">"+key+"</option>")

    window.wlanmap = map = new HMMap(netdata.wlandata)

    $('.wlanselect').on 'change', (event)->
      key = $('.wlanselect option:selected').val()
      map.setHeatMap(key)
      return
    
    key = $('.wlanselect option:first').val()
    map.setHeatMap(key)
    