# frozen_string_literal: true

module USB
  class Device
    include Comparable

    attr_reader :context

    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_unref_device(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(context, ptr, ref: true)
      raise ArgumentError, "device pointer is required" if ptr.nil? || ptr.null?

      @context = context
      @ptr = ptr
      @owns_ref = ref

      FFIBindings.libusb_ref_device(@ptr) if @owns_ref
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr)) if @owns_ref
    end

    def bus_number
      FFIBindings.libusb_get_bus_number(@ptr)
    end

    def device_address
      FFIBindings.libusb_get_device_address(@ptr)
    end

    def port_number
      FFIBindings.libusb_get_port_number(@ptr)
    end

    def port_numbers
      buffer = FFI::MemoryPointer.new(:uint8, 16)
      count = Error.raise_on_error(FFIBindings.libusb_get_port_numbers(@ptr, buffer, 16))
      buffer.read_array_of_uint8(count)
    end

    def speed
      Error.raise_on_error(FFIBindings.libusb_get_device_speed(@ptr))
    end

    def max_packet_size(endpoint)
      Error.raise_on_error(FFIBindings.libusb_get_max_packet_size(@ptr, endpoint))
    end

    def max_iso_packet_size(endpoint)
      Error.raise_on_error(FFIBindings.libusb_get_max_iso_packet_size(@ptr, endpoint))
    end

    def parent
      parent_ptr = FFIBindings.libusb_get_parent(@ptr)
      return nil if parent_ptr.null?

      Device.new(@context, parent_ptr)
    end

    def device_descriptor
      descriptor_ptr = FFI::MemoryPointer.new(FFIBindings::DeviceDescriptorStruct)
      Error.raise_on_error(FFIBindings.libusb_get_device_descriptor(@ptr, descriptor_ptr))
      DeviceDescriptor.new(FFIBindings::DeviceDescriptorStruct.new(descriptor_ptr))
    end

    def vendor_id
      device_descriptor.vendor_id
    end

    def product_id
      device_descriptor.product_id
    end

    def device_class
      device_descriptor.device_class
    end

    def config_descriptors
      Array.new(device_descriptor.num_configurations) { |index| config_descriptor(index) }
    end

    def active_config_descriptor
      fetch_config_descriptor(:libusb_get_active_config_descriptor)
    end

    def config_descriptor(index)
      fetch_config_descriptor(:libusb_get_config_descriptor, index)
    end

    def config_descriptor_by_value(value)
      fetch_config_descriptor(:libusb_get_config_descriptor_by_value, value)
    end

    def open
      handle_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(FFIBindings.libusb_open(@ptr, handle_ptr))
      handle = DeviceHandle.new(handle_ptr.read_pointer)
      return handle unless block_given?

      begin
        yield handle
      ensure
        handle.close
      end
    end

    def <=>(other)
      [bus_number, device_address] <=> [other.bus_number, other.device_address]
    end

    def inspect
      ids = format("%04x:%04x", vendor_id, product_id)
      format("#<USB::Device %03d/%03d %s>", bus_number, device_address, ids)
    rescue StandardError
      format("#<USB::Device %03d/%03d>", bus_number, device_address)
    end

    def to_ptr
      @ptr
    end

    private

    def fetch_config_descriptor(function_name, *args)
      descriptor_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(FFIBindings.public_send(function_name, @ptr, *args, descriptor_ptr))
      ConfigDescriptor.new(descriptor_ptr.read_pointer)
    end
  end
end
