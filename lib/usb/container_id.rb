# frozen_string_literal: true

module USB
  class ContainerID
    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_free_container_id_descriptor(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(ptr)
      raise ArgumentError, "container ID pointer is required" if ptr.nil? || ptr.null?

      @ptr = ptr
      @struct = FFIBindings::ContainerIDStruct.new(@ptr)
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))
    end

    def container_id
      @struct[:ContainerID].to_a
    end

    def close
      return if @ptr.nil? || @ptr.null?

      ObjectSpace.undefine_finalizer(self)
      FFIBindings.libusb_free_container_id_descriptor(@ptr)
      @ptr = FFI::Pointer::NULL
      @struct = nil
    end

    alias free close

    def to_ptr
      @ptr
    end

    def inspect
      "#<USB::ContainerID #{container_id.map { |byte| format('%02x', byte) }.join}>"
    end
  end
end
