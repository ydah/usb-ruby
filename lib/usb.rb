# frozen_string_literal: true

require "ffi"

require_relative "usb/version"
require_relative "usb/constants"
require_relative "usb/error"
require_relative "usb/ffi_bindings"
require_relative "usb/context"
require_relative "usb/device"
require_relative "usb/device_handle"
require_relative "usb/device_descriptor"
require_relative "usb/config_descriptor"
require_relative "usb/interface"
require_relative "usb/interface_descriptor"
require_relative "usb/endpoint_descriptor"
require_relative "usb/ss_endpoint_companion"
require_relative "usb/bos_descriptor"
require_relative "usb/bos_dev_capability"
require_relative "usb/usb20_extension"
require_relative "usb/ss_device_capability"
require_relative "usb/container_id"
require_relative "usb/transfer"
require_relative "usb/iso_packet"
require_relative "usb/hotplug"
require_relative "usb/event_handling"
require_relative "usb/pollfds"

module USB
  class << self
    def version
      FFIBindings.ensure_loaded!
      ptr = FFIBindings.libusb_get_version
      return nil if ptr.null?

      version = FFIBindings::VersionStruct.new(ptr)
      "#{version[:major]}.#{version[:minor]}.#{version[:micro]}"
    end

    def has_capability?(capability)
      FFIBindings.ensure_loaded!
      FFIBindings.libusb_has_capability(capability) != 0
    end

    def devices(**filters)
      Context.open { |context| context.devices(**filters) }
    end
  end
end
