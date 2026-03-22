# frozen_string_literal: true

require "rbconfig"

module USB
  module FFIBindings
    extend FFI::Library

    ffi_lib_flags :now, :global

    LIB_NAMES = case RbConfig::CONFIG["host_os"]
                when /darwin/
                  ["libusb-1.0.dylib", "libusb-1.0"]
                when /linux|bsd/
                  ["libusb-1.0.so.0", "libusb-1.0.so", "libusb-1.0"]
                when /mingw|mswin/
                  ["libusb-1.0.dll", "libusb-1.0"]
                else
                  ["libusb-1.0"]
                end.freeze

    @available_functions = {}

    begin
      ffi_lib(*LIB_NAMES)
      @library_loaded = true
    rescue LoadError => e
      @library_loaded = false
      @load_error = e
    end

    class << self
      attr_reader :load_error

      def library_loaded?
        @library_loaded
      end

      def ensure_loaded!
        return if library_loaded?

        raise LoadError, (@load_error&.message || "Unable to load libusb")
      end

      def function_available?(name)
        @available_functions.fetch(name.to_sym, false)
      end

      def attach_function_safe(name, args, returns, optional: false)
        if library_loaded?
          attach_function(name, args, returns)
          @available_functions[name.to_sym] = true
        else
          define_unavailable_function(name, optional: optional)
        end
      rescue FFI::NotFoundError => e
        define_unavailable_function(name, error: e, optional: optional)
      end

      def define_unavailable_function(name, error: nil, optional: false)
        @available_functions[name.to_sym] = false

        define_singleton_method(name) do |_ = nil, *|
          if optional
            raise NotImplementedError, (error&.message || "#{name} is not available in this libusb build")
          end

          ensure_loaded!
          raise LoadError, (error&.message || "#{name} is not available")
        end
      end
    end

    callback :hotplug_callback, [:pointer, :pointer, :int, :pointer], :int

    class TimevalStruct < FFI::Struct
      layout :tv_sec, :long,
             :tv_usec, :long
    end

    class DeviceDescriptorStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bcdUSB, :uint16,
             :bDeviceClass, :uint8,
             :bDeviceSubClass, :uint8,
             :bDeviceProtocol, :uint8,
             :bMaxPacketSize0, :uint8,
             :idVendor, :uint16,
             :idProduct, :uint16,
             :bcdDevice, :uint16,
             :iManufacturer, :uint8,
             :iProduct, :uint8,
             :iSerialNumber, :uint8,
             :bNumConfigurations, :uint8
    end

    class EndpointDescriptorStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bEndpointAddress, :uint8,
             :bmAttributes, :uint8,
             :wMaxPacketSize, :uint16,
             :bInterval, :uint8,
             :bRefresh, :uint8,
             :bSynchAddress, :uint8,
             :extra, :pointer,
             :extra_length, :int
    end

    class InterfaceDescriptorStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bInterfaceNumber, :uint8,
             :bAlternateSetting, :uint8,
             :bNumEndpoints, :uint8,
             :bInterfaceClass, :uint8,
             :bInterfaceSubClass, :uint8,
             :bInterfaceProtocol, :uint8,
             :iInterface, :uint8,
             :endpoint, :pointer,
             :extra, :pointer,
             :extra_length, :int
    end

    class InterfaceStruct < FFI::Struct
      layout :altsetting, :pointer,
             :num_altsetting, :int
    end

    class ConfigDescriptorStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :wTotalLength, :uint16,
             :bNumInterfaces, :uint8,
             :bConfigurationValue, :uint8,
             :iConfiguration, :uint8,
             :bmAttributes, :uint8,
             :MaxPower, :uint8,
             :interface, :pointer,
             :extra, :pointer,
             :extra_length, :int
    end

    class SSEndpointCompanionStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bMaxBurst, :uint8,
             :bmAttributes, :uint8,
             :wBytesPerInterval, :uint16
    end

    class BOSDescriptorStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :wTotalLength, :uint16,
             :bNumDeviceCaps, :uint8,
             :dev_capability, :pointer
    end

    class BOSDevCapabilityStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bDevCapabilityType, :uint8
    end

    class USB20ExtensionStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bDevCapabilityType, :uint8,
             :bmAttributes, :uint32
    end

    class SSDeviceCapabilityStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bDevCapabilityType, :uint8,
             :bmAttributes, :uint8,
             :wSpeedSupported, :uint16,
             :bFunctionalitySupport, :uint8,
             :bU1DevExitLat, :uint8,
             :bU2DevExitLat, :uint16
    end

    class ContainerIDStruct < FFI::Struct
      layout :bLength, :uint8,
             :bDescriptorType, :uint8,
             :bDevCapabilityType, :uint8,
             :bReserved, :uint8,
             :ContainerID, [:uint8, 16]
    end

    class TransferStruct < FFI::Struct
      layout :dev_handle, :pointer,
             :flags, :uint8,
             :endpoint, :uint8,
             :type, :uint8,
             :timeout, :uint,
             :status, :int,
             :length, :int,
             :actual_length, :int,
             :callback, :pointer,
             :user_data, :pointer,
             :buffer, :pointer,
             :num_iso_packets, :int
    end

    class IsoPacketDescriptorStruct < FFI::Struct
      layout :length, :uint,
             :actual_length, :uint,
             :status, :int
    end

    class PollfdStruct < FFI::Struct
      layout :fd, :int,
             :events, :short
    end

    class VersionStruct < FFI::Struct
      layout :major, :uint16,
             :minor, :uint16,
             :micro, :uint16,
             :nano, :uint16,
             :rc, :string,
             :describe, :string
    end

    attach_function_safe :libusb_init, [:pointer], :int
    attach_function_safe :libusb_init_context, [:pointer, :pointer, :int], :int, optional: true
    attach_function_safe :libusb_exit, [:pointer], :void
    attach_function_safe :libusb_set_debug, [:pointer, :int], :void
    attach_function_safe :libusb_set_option, [:pointer, :int, :varargs], :int, optional: true
    attach_function_safe :libusb_set_log_cb, [:pointer, :pointer, :int], :void, optional: true
    attach_function_safe :libusb_get_version, [], :pointer
    attach_function_safe :libusb_get_device_list, [:pointer, :pointer], :ssize_t
    attach_function_safe :libusb_free_device_list, [:pointer, :int], :void
    attach_function_safe :libusb_ref_device, [:pointer], :pointer
    attach_function_safe :libusb_unref_device, [:pointer], :void
    attach_function_safe :libusb_open, [:pointer, :pointer], :int
    attach_function_safe :libusb_close, [:pointer], :void
    attach_function_safe :libusb_open_device_with_vid_pid, [:pointer, :uint16, :uint16], :pointer
    attach_function_safe :libusb_get_device, [:pointer], :pointer
    attach_function_safe :libusb_get_bus_number, [:pointer], :uint8
    attach_function_safe :libusb_get_port_number, [:pointer], :uint8
    attach_function_safe :libusb_get_port_numbers, [:pointer, :pointer, :int], :int
    attach_function_safe :libusb_get_parent, [:pointer], :pointer
    attach_function_safe :libusb_get_device_address, [:pointer], :uint8
    attach_function_safe :libusb_get_device_speed, [:pointer], :int
    attach_function_safe :libusb_get_max_packet_size, [:pointer, :uint8], :int
    attach_function_safe :libusb_get_max_iso_packet_size, [:pointer, :uint8], :int
    attach_function_safe :libusb_get_max_alt_packet_size, [:pointer, :int, :int, :uint8], :int, optional: true
    attach_function_safe :libusb_wrap_sys_device, [:pointer, :long, :pointer], :int, optional: true
    attach_function_safe :libusb_get_configuration, [:pointer, :pointer], :int
    attach_function_safe :libusb_set_configuration, [:pointer, :int], :int
    attach_function_safe :libusb_claim_interface, [:pointer, :int], :int
    attach_function_safe :libusb_release_interface, [:pointer, :int], :int
    attach_function_safe :libusb_set_interface_alt_setting, [:pointer, :int, :int], :int
    attach_function_safe :libusb_clear_halt, [:pointer, :uint8], :int
    attach_function_safe :libusb_reset_device, [:pointer], :int
    attach_function_safe :libusb_kernel_driver_active, [:pointer, :int], :int
    attach_function_safe :libusb_detach_kernel_driver, [:pointer, :int], :int
    attach_function_safe :libusb_attach_kernel_driver, [:pointer, :int], :int
    attach_function_safe :libusb_set_auto_detach_kernel_driver, [:pointer, :int], :int
    attach_function_safe :libusb_has_capability, [:uint32], :int
    attach_function_safe :libusb_get_device_descriptor, [:pointer, :pointer], :int
    attach_function_safe :libusb_get_active_config_descriptor, [:pointer, :pointer], :int
    attach_function_safe :libusb_get_config_descriptor, [:pointer, :uint8, :pointer], :int
    attach_function_safe :libusb_get_config_descriptor_by_value, [:pointer, :uint8, :pointer], :int
    attach_function_safe :libusb_free_config_descriptor, [:pointer], :void
    attach_function_safe :libusb_get_ss_endpoint_companion_descriptor, [:pointer, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_free_ss_endpoint_companion_descriptor, [:pointer], :void, optional: true
    attach_function_safe :libusb_get_bos_descriptor, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_free_bos_descriptor, [:pointer], :void, optional: true
    attach_function_safe :libusb_get_usb_2_0_extension_descriptor, [:pointer, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_free_usb_2_0_extension_descriptor, [:pointer], :void, optional: true
    attach_function_safe :libusb_get_ss_usb_device_capability_descriptor, [:pointer, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_free_ss_usb_device_capability_descriptor, [:pointer], :void, optional: true
    attach_function_safe :libusb_get_container_id_descriptor, [:pointer, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_free_container_id_descriptor, [:pointer], :void, optional: true
    attach_function_safe :libusb_get_string_descriptor_ascii, [:pointer, :uint8, :pointer, :int], :int
    attach_function_safe :libusb_get_descriptor, [:pointer, :uint8, :uint8, :pointer, :int], :int
    attach_function_safe :libusb_get_string_descriptor, [:pointer, :uint8, :uint16, :pointer, :int], :int
    attach_function_safe :libusb_control_transfer, [:pointer, :uint8, :uint8, :uint16, :uint16, :pointer, :uint16, :uint], :int
    attach_function_safe :libusb_bulk_transfer, [:pointer, :uint8, :pointer, :int, :pointer, :uint], :int
    attach_function_safe :libusb_interrupt_transfer, [:pointer, :uint8, :pointer, :int, :pointer, :uint], :int
    attach_function_safe :libusb_alloc_transfer, [:int], :pointer, optional: true
    attach_function_safe :libusb_free_transfer, [:pointer], :void, optional: true
    attach_function_safe :libusb_submit_transfer, [:pointer], :int, optional: true
    attach_function_safe :libusb_cancel_transfer, [:pointer], :int, optional: true
    attach_function_safe :libusb_alloc_streams, [:pointer, :uint32, :pointer, :int], :int, optional: true
    attach_function_safe :libusb_free_streams, [:pointer, :pointer, :int], :int, optional: true
    attach_function_safe :libusb_try_lock_events, [:pointer], :int, optional: true
    attach_function_safe :libusb_lock_events, [:pointer], :void, optional: true
    attach_function_safe :libusb_unlock_events, [:pointer], :void, optional: true
    attach_function_safe :libusb_event_handling_ok, [:pointer], :int, optional: true
    attach_function_safe :libusb_event_handler_active, [:pointer], :int, optional: true
    attach_function_safe :libusb_interrupt_event_handler, [:pointer], :void, optional: true
    attach_function_safe :libusb_lock_event_waiters, [:pointer], :void, optional: true
    attach_function_safe :libusb_unlock_event_waiters, [:pointer], :void, optional: true
    attach_function_safe :libusb_wait_for_event, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_handle_events, [:pointer], :int, optional: true
    attach_function_safe :libusb_handle_events_timeout, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_handle_events_timeout_completed, [:pointer, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_handle_events_completed, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_handle_events_locked, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_get_next_timeout, [:pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_get_pollfds, [:pointer], :pointer, optional: true
    attach_function_safe :libusb_free_pollfds, [:pointer], :void, optional: true
    attach_function_safe :libusb_set_pollfd_notifiers, [:pointer, :pointer, :pointer, :pointer], :void, optional: true
    attach_function_safe :libusb_pollfds_handle_timeouts, [:pointer], :int, optional: true
    attach_function_safe :libusb_hotplug_register_callback, [:pointer, :int, :int, :int, :int, :int, :hotplug_callback, :pointer, :pointer], :int, optional: true
    attach_function_safe :libusb_hotplug_deregister_callback, [:pointer, :int], :void, optional: true
    attach_function_safe :libusb_error_name, [:int], :string
    attach_function_safe :libusb_strerror, [:int], :string
    attach_function_safe :libusb_setlocale, [:string], :int, optional: true
    attach_function_safe :libusb_dev_mem_alloc, [:pointer, :size_t], :pointer, optional: true
    attach_function_safe :libusb_dev_mem_free, [:pointer, :pointer, :size_t], :int, optional: true
  end
end
