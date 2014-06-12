require 'optparse'
require 'timeout'
require "wifiddler/version"

module WiFiddler
  class CLI
    class TooManyAttempts < StandardError; end

    STEP_DOWN_RATE  = 1.5

    attr_accessor :options

    def self.run(io, arguments)
      options = { io: io }
      options.merge! ArgumentParser.new.parse(arguments)
      self.new(options).run
    rescue ArgumentParser::InvalidOption => e
      io.puts e
      1
    end

    def initialize(options = {})
      self.options = options
    end

    def run
      Timeout::timeout(options[:timeout]) do
        wait_time = options[:interval]
        attempts = 0
        until network
          raise TooManyAttempts if attempts > options[:attempts]
          cycle_airport
          print '.'
          attempts += 1
          sleep wait_time
          wait_time *= STEP_DOWN_RATE
        end
      end
      self.io.puts "\nConnected to '#{network}'"
      0
    rescue TooManyAttempts
      self.io.puts "\nUnable to establish connection after #{options[:attempts]} attempts"
      1
    rescue Timeout::Error
      self.io.puts "\nUnable to establish connection after #{options[:timeout]} seconds"
      1
    end

    protected

    def io
      self.options[:io]
    end

    def networksetup(flag)
      std_read, std_write = IO.pipe
      err_read, err_write = IO.pipe
      command = "networksetup -#{flag}"
      self.io.puts command if options[:verbose]
      system(command, out: std_write, err: err_write)
      std_write.close
      err_write.close
      std_lines = std_read.readlines
      err_lines = err_read.readlines
      self.io.puts std_lines if options[:verbose]
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
      lines, errs = networksetup("getairportnetwork #{options[:device_id]}")
      lines.join('\n') =~ /Current Wi-Fi Network: (.+)$/i
      $1
    end

    def cycle_airport
      %w(off on).each do |state|
        networksetup("setairportpower - #{state}")
      end
    end

    class ArgumentParser
      class InvalidOption < StandardError
      end

      DEFAULT_OPTIONS = {
        device_id: "en0",
        interval: 10,
        attempts: 100,
        timeout:  10 * 60,
        verbose:  false
      }

      def parse(arguments)
        options = DEFAULT_OPTIONS.dup
        optparse = OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^\s{4}/, '')
            Cycle airport off & on until there is a connection
            Usage: wifiddler [options]
            Example: yourkarma --verbose
          BANNER

          opts.on('-i', '--interval=INTERVAL', "Seconds to wait after first cycle (default: #{DEFAULT_OPTIONS[:interval]})", Float) do |interval|
            options[:interval] = interval
          end
          opts.on('-t', '--timeout=TIMEOUT', "Seconds to wait before exiting (default: #{DEFAULT_OPTIONS[:timeout]})", Float) do |timeout|
            options[:timeout] = timeout
          end
          opts.on('-a', '--attempts=attempts', "Number of cycle attempts (default: #{DEFAULT_OPTIONS[:attempts]})", Integer) do |attempts|
            options[:attempts] = attempts
          end
          opts.on('-d', '--device=DEVICE_ID', "Airport device ID (default: #{DEFAULT_OPTIONS[:device_id]})", String) do |device_id|
            options[:device_id] = device_id
          end
          opts.on('-v', '--[no-]verbose', "Run verbosely (default: #{DEFAULT_OPTIONS[:verbose]})") do |v|
            options[:verbose] = true
          end
          opts.on('-h', '--help', 'Display this screen') do
            raise InvalidOption, opts
          end
        end

        optparse.parse!(arguments)

        options
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        raise InvalidOption, optparse
      end
    end
  end
end
