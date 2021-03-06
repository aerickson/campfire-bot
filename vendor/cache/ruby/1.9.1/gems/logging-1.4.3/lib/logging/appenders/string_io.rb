
module Logging::Appenders

  # This class provides an Appender that can write to a StringIO instance.
  # This is very useful for testing log message output.
  #
  class StringIo < ::Logging::Appenders::IO

    # The StringIO instance the appender is writing to.
    attr_reader :sio

    # call-seq:
    #    StringIo.new( name, opts = {} )
    #
    # Creates a new StrinIo appender that will append log messages to a
    # StringIO instance.
    #
    def initialize( name, opts = {} )
      @sio = StringIO.new
      @sio.extend IoToS
      @pos = 0
      super(name, @sio, opts)
    end

    # Clears the internal StringIO instance. All log messages are removed
    # from the buffer.
    #
    def clear
      sync {
        @pos = 0
        @sio.seek 0
        @sio.truncate 0
      }
    end
    alias :reset :clear

    %w[read readline readlines].each do|m|
      class_eval <<-CODE
        def #{m}( *args )
          sync {
            begin
              @sio.seek @pos
              rv = @sio.#{m}(*args)
              @pos = @sio.tell
              rv
            rescue EOFError
              nil
            end
          }
        end
      CODE
    end

    # :stopdoc:
    module IoToS
      def to_s
        seek 0
        str = read
        seek 0
        return str
      end
    end
    # :startdoc:

  end  # class StringIo
end  # module Logging::Appenders

# EOF
