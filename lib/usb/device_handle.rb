# frozen_string_literal: true

module USB
  class DeviceHandle
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_close(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(device_or_ptr)
      @ptr =
        case device_or_ptr
        when Device
          open_device(device_or_ptr)
        when FFI::Pointer
          device_or_ptr
        else
          raise ArgumentError, "expected USB::Device or FFI::Pointer"
        end

      raise ArgumentError, "device handle pointer is required" if @ptr.nil? || @ptr.null?

      @device = device_or_ptr if device_or_ptr.is_a?(Device)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def close
      return if closed?

      ObjectSpace.undefine_finalizer(self)
      FFIBindings.libusb_close(@ptr)
      @ptr = FFI::Pointer::NULL
    end

    def closed?
      @ptr.nil? || @ptr.null?
    end

    def device
      @device ||= begin
        device_ptr = FFIBindings.libusb_get_device(@ptr)
        device_ptr.null? ? nil : Device.new(nil, device_ptr)
      end
    end

    def configuration
      configuration_ptr = FFI::MemoryPointer.new(:int)
      Error.raise_on_error(FFIBindings.libusb_get_configuration(@ptr, configuration_ptr))
      configuration_ptr.read_int
    end

    def configuration=(value)
      Error.raise_on_error(FFIBindings.libusb_set_configuration(@ptr, value))
    end

    def claim_interface(number)
      Error.raise_on_error(FFIBindings.libusb_claim_interface(@ptr, number))
      self
    end

    def release_interface(number)
      Error.raise_on_error(FFIBindings.libusb_release_interface(@ptr, number))
      self
    end

    def set_interface_alt_setting(interface, alt_setting)
      Error.raise_on_error(FFIBindings.libusb_set_interface_alt_setting(@ptr, interface, alt_setting))
      self
    end

    def clear_halt(endpoint)
      Error.raise_on_error(FFIBindings.libusb_clear_halt(@ptr, endpoint))
      self
    end

    def reset_device
      Error.raise_on_error(FFIBindings.libusb_reset_device(@ptr))
      self
    end

    def kernel_driver_active?(interface)
      result = FFIBindings.libusb_kernel_driver_active(@ptr, interface)
      Error.raise_on_error(result) == 1
    end

    def detach_kernel_driver(interface)
      Error.raise_on_error(FFIBindings.libusb_detach_kernel_driver(@ptr, interface))
      self
    end

    def attach_kernel_driver(interface)
      Error.raise_on_error(FFIBindings.libusb_attach_kernel_driver(@ptr, interface))
      self
    end

    def auto_detach_kernel_driver=(enable)
      Error.raise_on_error(FFIBindings.libusb_set_auto_detach_kernel_driver(@ptr, enable ? 1 : 0))
    end

    def with_interface(number)
      claimed = false
      claim_interface(number)
      claimed = true
      yield self
    ensure
      release_interface(number) if claimed && !closed?
    end

    def control_transfer(bm_request_type:, b_request:, w_value:, w_index:, data_or_length: nil, timeout: 1000)
      if data_or_length.is_a?(Integer)
        buffer = FFI::MemoryPointer.new(:uint8, [data_or_length, 1].max)
        transferred = Error.raise_on_error(
          FFIBindings.libusb_control_transfer(
            @ptr, bm_request_type, b_request, w_value, w_index, buffer, data_or_length, timeout
          )
        )
        buffer.read_bytes(transferred)
      else
        data = data_or_length.nil? ? "".b : data_or_length.to_s.b
        buffer = bytes_pointer(data)
        Error.raise_on_error(
          FFIBindings.libusb_control_transfer(
            @ptr, bm_request_type, b_request, w_value, w_index, buffer, data.bytesize, timeout
          )
        )
      end
    end

    def bulk_transfer(endpoint:, data_or_length:, timeout: 1000)
      transferred = FFI::MemoryPointer.new(:int)

      if data_or_length.is_a?(Integer)
        buffer = FFI::MemoryPointer.new(:uint8, [data_or_length, 1].max)
        Error.raise_on_error(FFIBindings.libusb_bulk_transfer(@ptr, endpoint, buffer, data_or_length, transferred, timeout))
        buffer.read_bytes(transferred.read_int)
      else
        data = data_or_length.to_s.b
        buffer = bytes_pointer(data)
        Error.raise_on_error(FFIBindings.libusb_bulk_transfer(@ptr, endpoint, buffer, data.bytesize, transferred, timeout))
        transferred.read_int
      end
    end

    def interrupt_transfer(endpoint:, data_or_length:, timeout: 1000)
      transferred = FFI::MemoryPointer.new(:int)

      if data_or_length.is_a?(Integer)
        buffer = FFI::MemoryPointer.new(:uint8, [data_or_length, 1].max)
        Error.raise_on_error(
          FFIBindings.libusb_interrupt_transfer(@ptr, endpoint, buffer, data_or_length, transferred, timeout)
        )
        buffer.read_bytes(transferred.read_int)
      else
        data = data_or_length.to_s.b
        buffer = bytes_pointer(data)
        Error.raise_on_error(
          FFIBindings.libusb_interrupt_transfer(@ptr, endpoint, buffer, data.bytesize, transferred, timeout)
        )
        transferred.read_int
      end
    end

    def string_descriptor_ascii(index)
      return nil if index.to_i.zero?

      buffer = FFI::MemoryPointer.new(:uint8, 256)
      length = Error.raise_on_error(FFIBindings.libusb_get_string_descriptor_ascii(@ptr, index, buffer, 256))
      buffer.read_string_length(length)
    end

    def manufacturer
      string_descriptor_ascii(device.device_descriptor.manufacturer_index)
    end

    def product
      string_descriptor_ascii(device.device_descriptor.product_index)
    end

    def serial_number
      string_descriptor_ascii(device.device_descriptor.serial_number_index)
    end

    def alloc_streams(num_streams, endpoints)
      endpoint_ptr = endpoint_array_pointer(endpoints)
      Error.raise_on_error(FFIBindings.libusb_alloc_streams(@ptr, num_streams, endpoint_ptr, endpoints.length))
    end

    def free_streams(endpoints)
      endpoint_ptr = endpoint_array_pointer(endpoints)
      Error.raise_on_error(FFIBindings.libusb_free_streams(@ptr, endpoint_ptr, endpoints.length))
    end

    def dev_mem_alloc(length)
      FFIBindings.libusb_dev_mem_alloc(@ptr, length)
    end

    def dev_mem_free(buffer, length)
      Error.raise_on_error(FFIBindings.libusb_dev_mem_free(@ptr, buffer, length))
    end

    def bos_descriptor
      descriptor_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(FFIBindings.libusb_get_bos_descriptor(@ptr, descriptor_ptr))
      BOSDescriptor.new(descriptor_ptr.read_pointer)
    end

    def to_ptr
      @ptr
    end

    def inspect
      descriptor = device&.device_descriptor
      if descriptor
        format("#<USB::DeviceHandle %04x:%04x>", descriptor.vendor_id, descriptor.product_id)
      else
        "#<USB::DeviceHandle>"
      end
    rescue StandardError
      "#<USB::DeviceHandle>"
    end

    private

    def open_device(device)
      handle_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(FFIBindings.libusb_open(device.to_ptr, handle_ptr))
      handle_ptr.read_pointer
    end

    def bytes_pointer(data)
      pointer = FFI::MemoryPointer.new(:uint8, [data.bytesize, 1].max)
      pointer.put_bytes(0, data) unless data.empty?
      pointer
    end

    def endpoint_array_pointer(endpoints)
      pointer = FFI::MemoryPointer.new(:uint8, endpoints.length)
      endpoints.each_with_index do |endpoint, index|
        pointer.put_uint8(index, endpoint)
      end
      pointer
    end
  end
end
