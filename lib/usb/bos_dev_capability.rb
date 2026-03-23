# frozen_string_literal: true

module USB
  class BOSDevCapability
    def initialize(ptr, bos_descriptor = nil)
      raise ArgumentError, "BOS capability pointer is required" if ptr.nil? || ptr.null?

      @bos_descriptor = bos_descriptor
      @ptr = ptr
      @struct = FFIBindings::BOSDevCapabilityStruct.new(@ptr)
    end

    def capability_type
      @struct[:bDevCapabilityType]
    end

    def data
      length = @struct[:bLength] - 3
      return "".b if length <= 0

      (@ptr + 3).read_bytes(length)
    end

    def usb_2_0_extension(context)
      fetch_descriptor(context, :libusb_get_usb_2_0_extension_descriptor, USB20Extension)
    end

    def ss_device_capability(context)
      fetch_descriptor(context, :libusb_get_ss_usb_device_capability_descriptor, SSDeviceCapability)
    end

    def container_id(context)
      fetch_descriptor(context, :libusb_get_container_id_descriptor, ContainerID)
    end

    def inspect
      "#<USB::BOSDevCapability type=#{capability_type}>"
    end

    private

    def fetch_descriptor(context, function_name, klass)
      descriptor_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(FFIBindings.public_send(function_name, context.to_ptr, @ptr, descriptor_ptr))
      klass.new(descriptor_ptr.read_pointer)
    end
  end
end
