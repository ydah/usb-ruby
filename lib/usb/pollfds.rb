# frozen_string_literal: true

module USB
  class Pollfd
    def self.from_values(fd, events)
      new(FFIBindings::PollfdStruct.new(build_pointer(fd, events)))
    end

    def self.build_pointer(fd, events)
      pointer = FFI::MemoryPointer.new(FFIBindings::PollfdStruct)
      struct = FFIBindings::PollfdStruct.new(pointer)
      struct[:fd] = fd
      struct[:events] = events
      pointer
    end

    def initialize(source)
      @struct = source.is_a?(FFIBindings::PollfdStruct) ? source : FFIBindings::PollfdStruct.new(source)
    end

    def fd
      @struct[:fd]
    end

    def events
      @struct[:events]
    end

    def inspect
      "#<USB::Pollfd fd=#{fd} events=0x#{events.to_s(16)}>"
    end
  end
end
