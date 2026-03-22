# frozen_string_literal: true

module USB
  module Hotplug
    def on_hotplug_event(events:, vendor_id: HOTPLUG_MATCH_ANY, product_id: HOTPLUG_MATCH_ANY,
                         device_class: HOTPLUG_MATCH_ANY, flags: 0, &block)
      raise ArgumentError, "block required" unless block

      callback_handle = nil
      callback = FFI::Function.new(:int, [:pointer, :pointer, :int, :pointer]) do |_ctx_ptr, device_ptr, event, _user_data|
        device = Device.new(self, device_ptr)
        result = block.call(device, event)
        @hotplug_callbacks.delete(callback_handle) if result == true && callback_handle
        result == true ? 1 : 0
      end

      handle_ptr = FFI::MemoryPointer.new(:int)
      Error.raise_on_error(
        FFIBindings.libusb_hotplug_register_callback(
          @ptr,
          events,
          flags,
          vendor_id,
          product_id,
          device_class,
          callback,
          nil,
          handle_ptr
        )
      )

      callback_handle = handle_ptr.read_int
      @hotplug_callbacks[callback_handle] = callback
      callback_handle
    end

    def deregister_hotplug(handle)
      callback = @hotplug_callbacks.delete(handle)
      return unless callback

      FFIBindings.libusb_hotplug_deregister_callback(@ptr, handle)
      nil
    end
  end

  Context.include(Hotplug)
end
