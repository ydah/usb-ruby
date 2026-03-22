# frozen_string_literal: true

module USB
  class InterfaceDescriptor
    include Enumerable

    def initialize(interface, struct)
      @interface = interface
      @struct = struct
    end

    def interface_number
      @struct[:bInterfaceNumber]
    end

    def alternate_setting
      @struct[:bAlternateSetting]
    end

    def num_endpoints
      @struct[:bNumEndpoints]
    end

    def interface_class
      @struct[:bInterfaceClass]
    end

    def interface_sub_class
      @struct[:bInterfaceSubClass]
    end

    def interface_protocol
      @struct[:bInterfaceProtocol]
    end

    def description_index
      @struct[:iInterface]
    end

    def endpoints
      count = num_endpoints
      base_ptr = @struct[:endpoint]
      return [] if base_ptr.null?

      Array.new(count) do |index|
        offset = index * FFIBindings::EndpointDescriptorStruct.size
        EndpointDescriptor.new(self, FFIBindings::EndpointDescriptorStruct.new(base_ptr + offset))
      end
    end

    def each(&block)
      endpoints.each(&block)
    end

    def extra
      return "".b if @struct[:extra].null? || @struct[:extra_length].zero?

      @struct[:extra].read_bytes(@struct[:extra_length])
    end

    def inspect
      "#<USB::InterfaceDescriptor number=#{interface_number} alt=#{alternate_setting} endpoints=#{num_endpoints}>"
    end
  end
end
