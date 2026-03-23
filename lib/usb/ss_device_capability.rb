# frozen_string_literal: true

module USB
  class SSDeviceCapability
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_ss_usb_device_capability_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "SS device capability pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::SSDeviceCapabilityStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def attributes
      @struct[:bmAttributes]
    end

    def speed_supported
      @struct[:wSpeedSupported]
    end

    def functionality_support
      @struct[:bFunctionalitySupport]
    end

    def u1_dev_exit_lat
      @struct[:bU1DevExitLat]
    end

    def u2_dev_exit_lat
      @struct[:bU2DevExitLat]
    end

    def close
      return if @ptr.nil? || @ptr.null?

      ObjectSpace.undefine_finalizer(self)
      FFIBindings.libusb_free_ss_usb_device_capability_descriptor(@ptr)
      @ptr = FFI::Pointer::NULL
      @struct = nil
    end

    alias free close

    def to_ptr
      @ptr
    end

    def inspect
      "#<USB::SSDeviceCapability speed_supported=0x#{speed_supported.to_s(16)}>"
    end
  end
end
