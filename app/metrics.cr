# Basic metric reporting in StatsD / DataDog format ("Line Protocol") using UDP.
# Note: Tags are an extension of DataDog, and are not supported natively by StatsD.
#
# Structure: <METRIC_NAME>:<VALUE>|<TYPE>|@<SAMPLE_RATE>|#<TAG_KEY_1>:<TAG_VALUE_1>,<TAG_2>

abstract struct BaseMetricReporter
  def send(message : String) end
  def send(name : String, value : String, type : Char) end
  def send(name : String, value : String, type : Char, rate : UInt8) end
  def send(name : String, value : String, type : Char, tags : Array(String)) end
  def send(name : String, value : String, type : Char, rate : UInt8, tags : Array(String)) end

  # COUNT

  def count(name : String) end
  def count(name : String, rate : UInt8) end
  def count(name : String, tags : Array(String)) end
  def count(name : String, rate : UInt8, tags : Array(String)) end

  # HISTOGRAM

  def histogram(name : String, value : String) end
  def histogram(name : String, value : String, rate : UInt8) end
  def histogram(name : String, value : String, tags : Array(String)) end
  def histogram(name : String, value : String, rate : UInt8, tags : Array(String)) end
end

struct NoOpMetricReporter < BaseMetricReporter
end

struct UDPMetricReporter < BaseMetricReporter
  @client : UDPSocket
  
  def initialize(host : String, port : Int32)
    begin
      client = UDPSocket.new
      client.connect host, port
    rescue ex : Socket::Addrinfo::Error
      STDERR << "Could not find metrics endpoint: " << ex.inspect << "\n"
      exit
    end
    @client = client
  end

  def send(message : String)
	  begin
		  @client.send message
	  rescue ex : Errno
		  STDERR << "Error sending metric: " << ex.inspect << "\n"
	  end
  end

  def send(name : String, value : String, type : Char)
	  self.send "#{name}:#{value}|#{type}"
  end

  def send(name : String, value : String, type : Char, rate : UInt8)
	  self.send "#{name}:#{value}|#{type}|@#{rate}"
  end

  def send(name : String, value : String, type : Char, tags : Array(String))
	  if tags.size == 0
		  self.send name, value, type
	  else
		  self.send "#{name}:#{value}|#{type}|##{tags.join(',')}"
	  end
  end

  def send(name : String, value : String, type : Char, rate : UInt8, tags : Array(String))
	  if tags.size == 0
		  self.send name, value, type, rate
	  else
		  self.send "#{name}:#{value}|#{type}|@#{rate}|##{tags.join(',')}"
	  end
  end

  # COUNT

  def count(name : String)
	  self.send name, "1", 'c'
  end

  def count(name : String, rate : UInt8)
    self.send name, "1", 'c', rate
  end

  def count(name : String, tags : Array(String))
	  self.send name, "1", 'c', tags
  end

  def count(name : String, rate : UInt8, tags : Array(String))
	  self.send name, "1", 'c', rate, tags
  end

  # HISTOGRAM

  def histogram(name : String, value : String)
	  self.send name, value, 'h'
  end

  def histogram(name : String, value : String, rate : UInt8)
	  self.send name, value, 'h', rate
  end

  def histogram(name : String, value : String, tags : Array(String))
	  self.send name, value, 'h', tags
  end

  def histogram(name : String, value : String, rate : UInt8, tags : Array(String))
	  self.send name, value, 'h', rate, tags
  end
end