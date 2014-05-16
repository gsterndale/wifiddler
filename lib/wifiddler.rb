require 'timeout'
require "wifiddler/version"

module WiFiddler
  class CLI
    INTERVAL        = 10
    STEP_DOWN_RATE          = 1.5
    DEVICE_ID       = "en0"
    NETWORK_SERVICE = "Wi-Fi"
    VERBOSE         = false

    attr_accessor :io

    def self.run(io, arguments)
      self.new(io).run
    end

    def initialize(io)
      self.io = io
    end

    def run
      Timeout::timeout(60) do
        wait_time = INTERVAL
        until network
          cycle_airport
          print '.'
          sleep wait_time
          wait_time *= STEP_DOWN_RATE
        end
      end
      self.io.puts "\nConnected to '#{network}'"
      0
    rescue Timeout::Error
      self.io.puts "\nUnable to connect to router"
      1
    end

    private

    def networksetup(flag)
      std_read, std_write = IO.pipe
      err_read, err_write = IO.pipe
      command = "networksetup -#{flag}"
      self.io.puts command if VERBOSE
      system(command, out: std_write, err: err_write)
      std_write.close
      err_write.close
      std_lines = std_read.readlines
      err_lines = err_read.readlines
      self.io.puts std_lines if VERBOSE
      return std_lines, err_lines
    end


    # There seem to be three variations of output:
    # 1.
    # You are not associated with an AirPort network.
    #
    # 2.
    # You are not associated with an AirPort network.
    # Wi-Fi power is currently off.
    #
    # 3.
    # Current Wi-Fi Network: Karma Wi-Fi
    def network
      lines, errs = networksetup("getairportnetwork #{DEVICE_ID}")
      lines.join('\n') =~ /Current Wi-Fi Network: (.+)$/i
      $1
    end

    def cycle_airport
      %w(off on).each do |state|
        networksetup("setairportpower - #{state}")
      end
    end
  end
end
