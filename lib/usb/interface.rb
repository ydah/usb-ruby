# frozen_string_literal: true

module USB
  class Interface
    include Enumerable

    def initialize(config_descriptor, struct)
      @config_descriptor = config_descriptor
      @struct = struct
    end

    def alt_settings
      count = @struct[:num_altsetting]
      base_ptr = @struct[:altsetting]
      return [] if base_ptr.null?

      Array.new(count) do |index|
        offset = index * FFIBindings::InterfaceDescriptorStruct.size
        InterfaceDescriptor.new(self, FFIBindings::InterfaceDescriptorStruct.new(base_ptr + offset))
      end
    end

    def each(&block)
      alt_settings.each(&block)
    end

    def inspect
      "#<USB::Interface alt_settings=#{@struct[:num_altsetting]}>"
    end
  end
end
