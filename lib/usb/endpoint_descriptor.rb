# frozen_string_literal: true

module USB
  class EndpointDescriptor
    def initialize(interface_descriptor, struct)
      @interface_descriptor = interface_descriptor
      @struct = struct
    end

    def endpoint_address
      @struct[:bEndpointAddress]
    end

    def direction
      in? ? :in : :out
    end

    def transfer_type
      case @struct[:bmAttributes] & 0x03
      when TRANSFER_TYPE_CONTROL then :control
      when TRANSFER_TYPE_ISOCHRONOUS then :isochronous
      when TRANSFER_TYPE_BULK then :bulk
      when TRANSFER_TYPE_INTERRUPT then :interrupt
      else
        :unknown
      end
    end

    def max_packet_size
      @struct[:wMaxPacketSize]
    end

    def interval
      @struct[:bInterval]
    end

    def refresh
      @struct[:bRefresh]
    end

    def synch_address
      @struct[:bSynchAddress]
    end

    def extra
      return "".b if @struct[:extra].null? || @struct[:extra_length].zero?

      @struct[:extra].read_bytes(@struct[:extra_length])
    end

    def ss_endpoint_companion(context)
      descriptor_ptr = FFI::MemoryPointer.new(:pointer)
      Error.raise_on_error(
        FFIBindings.libusb_get_ss_endpoint_companion_descriptor(context.to_ptr, @struct.pointer, descriptor_ptr)
      )
      SSEndpointCompanion.new(descriptor_ptr.read_pointer)
    end

    def in?
      (endpoint_address & ENDPOINT_IN) == ENDPOINT_IN
    end

    def out?
      !in?
    end

    def bulk?
      transfer_type == :bulk
    end

    def interrupt?
      transfer_type == :interrupt
    end

    def isochronous?
      transfer_type == :isochronous
    end

    def control?
      transfer_type == :control
    end

    def inspect
      format("#<USB::EndpointDescriptor 0x%02x %s %s>", endpoint_address, transfer_type, direction)
    end

    def to_ptr
      @struct.pointer
    end
  end
end
