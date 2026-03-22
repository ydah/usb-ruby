# frozen_string_literal: true

module USB
  class BOSDescriptor
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_bos_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "BOS descriptor pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::BOSDescriptorStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def num_device_caps
      @struct[:bNumDeviceCaps]
    end

    def device_capabilities
      count = num_device_caps
      base_ptr = @struct[:dev_capability]
      return [] if base_ptr.null?

      Array.new(count) do |index|
        capability_ptr = base_ptr.get_pointer(index * FFI::Pointer.size)
        BOSDevCapability.new(capability_ptr)
      end
    end

    def inspect
      "#<USB::BOSDescriptor device_caps=#{num_device_caps}>"
    end
  end
end
