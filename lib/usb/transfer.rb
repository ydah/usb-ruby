# frozen_string_literal: true

module USB
  class Transfer
    CALLBACK = FFI::Function.new(:void, [:pointer]) do |transfer_ptr|
      transfer = from_pointer(transfer_ptr)
      transfer&.send(:invoke_callback)
    end

    class << self
      def registry
        @registry ||= {}
      end

      def from_pointer(ptr)
        registry[ptr.address]
      end

      def control(handle:, bm_request_type:, b_request:, w_value:, w_index:, data_or_length:, timeout: 1000)
        data =
          if data_or_length.is_a?(Integer)
            "\x00".b * data_or_length
          else
            data_or_length.to_s.b
          end

        setup = [bm_request_type, b_request, w_value, w_index, data.bytesize].pack("CCvvv")
        transfer = new
        transfer.dev_handle = handle
        transfer.type = TRANSFER_TYPE_CONTROL
        transfer.timeout = timeout
        transfer.buffer = setup + data
        transfer
      end

      def bulk(handle:, endpoint:, data:, timeout: 1000)
        transfer = new
        transfer.dev_handle = handle
        transfer.endpoint = endpoint
        transfer.type = TRANSFER_TYPE_BULK
        transfer.timeout = timeout
        transfer.buffer = data
        transfer
      end

      def interrupt(handle:, endpoint:, data:, timeout: 1000)
        transfer = new
        transfer.dev_handle = handle
        transfer.endpoint = endpoint
        transfer.type = TRANSFER_TYPE_INTERRUPT
        transfer.timeout = timeout
        transfer.buffer = data
        transfer
      end

      def isochronous(handle:, endpoint:, data:, num_iso_packets:, timeout: 1000)
        transfer = new(num_iso_packets: num_iso_packets)
        transfer.dev_handle = handle
        transfer.endpoint = endpoint
        transfer.type = TRANSFER_TYPE_ISOCHRONOUS
        transfer.timeout = timeout
        transfer.buffer = data
        transfer
      end
    end

    def initialize(num_iso_packets: 0)
      FFIBindings.ensure_loaded!
      @ptr = FFIBindings.libusb_alloc_transfer(num_iso_packets)
      raise Error, "libusb_alloc_transfer returned null" if @ptr.null?

      @struct = FFIBindings::TransferStruct.new(@ptr)
      @struct[:callback] = CALLBACK
      @struct[:user_data] = FFI::Pointer::NULL
      @callback = nil
      @buffer = nil
    end

    def free
      return if @ptr.nil? || @ptr.null?

      self.class.registry.delete(@ptr.address)
      FFIBindings.libusb_free_transfer(@ptr)
      @ptr = FFI::Pointer::NULL
      @struct = nil
      @buffer = nil
    end

    def dev_handle=(handle)
      @struct[:dev_handle] = handle.is_a?(DeviceHandle) ? handle.to_ptr : handle
    end

    def endpoint=(endpoint)
      @struct[:endpoint] = endpoint
    end

    def type=(transfer_type)
      @struct[:type] = transfer_type
    end

    def timeout=(milliseconds)
      @struct[:timeout] = milliseconds
    end

    def buffer=(data)
      bytes = data.to_s.b
      @buffer = FFI::MemoryPointer.new(:uint8, [bytes.bytesize, 1].max)
      @buffer.put_bytes(0, bytes) unless bytes.empty?
      @struct[:buffer] = @buffer
      @struct[:length] = bytes.bytesize
    end

    def flags
      @struct[:flags]
    end

    def flags=(value)
      @struct[:flags] = value
    end

    def status
      @struct[:status]
    end

    def actual_length
      @struct[:actual_length]
    end

    def submit
      self.class.registry[@ptr.address] = self
      Error.raise_on_error(FFIBindings.libusb_submit_transfer(@ptr))
      self
    rescue StandardError
      self.class.registry.delete(@ptr.address)
      raise
    end

    def cancel
      Error.raise_on_error(FFIBindings.libusb_cancel_transfer(@ptr))
      self
    end

    def on_complete(&block)
      @callback = block
      self
    end

    def callback
      @callback
    end

    def iso_packet(index)
      raise IndexError, "iso packet index out of bounds" if index.negative? || index >= num_iso_packets

      IsoPacket.new(self, FFIBindings::IsoPacketDescriptorStruct.new(iso_packet_pointer(index)))
    end

    def set_iso_packet_lengths(length)
      num_iso_packets.times do |index|
        iso_packet(index).length = length
      end
      self
    end

    def num_iso_packets
      @struct[:num_iso_packets]
    end

    def to_ptr
      @ptr
    end

    private

    def invoke_callback
      self.class.registry.delete(@ptr.address)
      @callback&.call(self)
    end

    def iso_packet_pointer(index)
      @ptr + FFIBindings::TransferStruct.size + (index * FFIBindings::IsoPacketDescriptorStruct.size)
    end
  end
end
