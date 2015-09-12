require 'rubygems'
require 'bundler/setup'
require 'csv'
require 'rethinkdb'


class WifiCSVParser
  attr_accessor :data
  def initialize(datafile)
    @datafile = datafile
    parse
  end

  protected
  def parse
    @data = CSV.read(@datafile)
  end
end

class DB
  def initialize
    connect
  end

  # want array of arrays or single dataset
  def insert(data)
    if data.is_a?(Array) and data[0].is_a?(Array)
      data.each do |arraydata|
        process_and_insert(arraydata)
      end
    elsif data.is_a?(Array) and data[0].is_a?(String)
      process_and_insert(data)
    else
      raise
    end
  end


  protected

  # clean up and dont insert if empty data
  def process_and_insert(dataset)
    begin
      dataset.each do |field|
        if field.nil? or field.empty?
          raise
        end
      end
      newdataset = parse_wifi_data(dataset)
      db_insert(newdataset)
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    ensure
      
    end

  end

  # parse wifidata and reduce
  def parse_wifi_data(dataset)
    datahash = {
      date: dataset[0], # date
      lat: dataset[4],
      lon: dataset[5],
      alti: dataset[6],
      ssid: dataset[11],
      bssid: dataset[12],
      rssi:  dataset[13],
      accuracy: dataset[7]
    }
    return datahash
  end
end

class Rethinkdb < DB
  include RethinkDB::Shortcuts
  def initialize

    @host = 'localhost'
    @port = '28015'
    @db = 'wifidata'
    @table = 'logdata'
    super
    setup
  end

  protected
  def connect
    r.connect(host: @host,port: @port).repl
  end

  def db_insert(dataset)
    r.db(@db).table(@table).insert(dataset).run
  end

  def setup
    begin
      r.db_create(@db).run
    rescue
    end
    begin
      r.db(@db).table_create(@table).run
    rescue Exception => e
      e.message
    end
    begin
      r.db(@db).table(@table).index_create("date").run
    rescue
    end
  end
end
csvfile = "data/wifilog.csv"
@wifidata = WifiCSVParser.new(csvfile)
@db = Rethinkdb.new
@db.insert @wifidata.data
