# frozen_string_literal: true

module USB
  class USB20Extension
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_usb_2_0_extension_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "USB 2.0 extension pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::USB20ExtensionStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def attributes
      @struct[:bmAttributes]
    end

    def supports_lpm?
      (attributes & 0x02) != 0
    end

    def inspect
      "#<USB::USB20Extension attributes=0x#{attributes.to_s(16)}>"
    end
  end
end
