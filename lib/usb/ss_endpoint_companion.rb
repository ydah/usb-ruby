# frozen_string_literal: true

module USB
  class SSEndpointCompanion
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_ss_endpoint_companion_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "SS endpoint companion pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::SSEndpointCompanionStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def max_burst
      @struct[:bMaxBurst]
    end

    def attributes
      @struct[:bmAttributes]
    end

    def bytes_per_interval
      @struct[:wBytesPerInterval]
    end

    def close
      return if @ptr.nil? || @ptr.null?

      ObjectSpace.undefine_finalizer(self)
      FFIBindings.libusb_free_ss_endpoint_companion_descriptor(@ptr)
      @ptr = FFI::Pointer::NULL
      @struct = nil
    end

    alias free close

    def to_ptr
      @ptr
    end

    def inspect
      "#<USB::SSEndpointCompanion max_burst=#{max_burst} bytes_per_interval=#{bytes_per_interval}>"
    end
  end
end
