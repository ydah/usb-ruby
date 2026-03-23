# frozen_string_literal: true

module USB
  class ConfigDescriptor
    include Enumerable

    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_config_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "config descriptor pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::ConfigDescriptorStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def configuration_value
      @struct[:bConfigurationValue]
    end

    def description_index
      @struct[:iConfiguration]
    end

    def attributes
      @struct[:bmAttributes]
    end

    def max_power
      @struct[:MaxPower]
    end

    def num_interfaces
      @struct[:bNumInterfaces]
    end

    def interfaces
      count = num_interfaces
      base_ptr = @struct[:interface]
      return [] if base_ptr.null?

      Array.new(count) do |index|
        offset = index * FFIBindings::InterfaceStruct.size
        Interface.new(self, FFIBindings::InterfaceStruct.new(base_ptr + offset))
      end
    end

    def each(&block)
      interfaces.each(&block)
    end

    def extra
      read_extra(@struct[:extra], @struct[:extra_length])
    end

    def self_powered?
      (attributes & 0x40) != 0
    end

    def remote_wakeup?
      (attributes & 0x20) != 0
    end

    def close
      return if @ptr.nil? || @ptr.null?

      ObjectSpace.undefine_finalizer(self)
      FFIBindings.libusb_free_config_descriptor(@ptr)
      @ptr = FFI::Pointer::NULL
      @struct = nil
    end

    def inspect
      "#<USB::ConfigDescriptor value=#{configuration_value} interfaces=#{num_interfaces}>"
    end

    def to_ptr
      @ptr
    end

    private

    def read_extra(ptr, length)
      return "".b if ptr.null? || length.zero?

      ptr.read_bytes(length)
    end
  end
end
