# frozen_string_literal: true

module USB
  class DeviceDescriptor
    def initialize(struct)
      @struct = struct
    end

    def bcd_usb
      @struct[:bcdUSB]
    end

    def device_class
      @struct[:bDeviceClass]
    end

    def device_sub_class
      @struct[:bDeviceSubClass]
    end

    def device_protocol
      @struct[:bDeviceProtocol]
    end

    def max_packet_size_0
      @struct[:bMaxPacketSize0]
    end

    def vendor_id
      @struct[:idVendor]
    end

    def product_id
      @struct[:idProduct]
    end

    def bcd_device
      @struct[:bcdDevice]
    end

    def manufacturer_index
      @struct[:iManufacturer]
    end

    def product_index
      @struct[:iProduct]
    end

    def serial_number_index
      @struct[:iSerialNumber]
    end

    def num_configurations
      @struct[:bNumConfigurations]
    end

    def inspect
      format("#<USB::DeviceDescriptor %04x:%04x class=0x%02x>", vendor_id, product_id, device_class)
    end
  end
end
