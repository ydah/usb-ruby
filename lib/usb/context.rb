# frozen_string_literal: true

module USB
  class Context
    attr_reader :ptr

    def self.open(**options)
      context = new(**options)
      return context unless block_given?

      begin
        yield context
      ensure
        context.close
      end
    end

    def self.finalizer(ptr)
      proc do
        FFIBindings.libusb_exit(ptr) unless ptr.nil? || ptr.null?
      rescue StandardError
      end
    end

    def initialize(options: nil, **kwargs)
      FFIBindings.ensure_loaded!
      options = (options || {}).merge(kwargs)

      context_ptr = FFI::MemoryPointer.new(:pointer)

      if !options.empty? && FFIBindings.function_available?(:libusb_init_context)
        Error.raise_on_error(FFIBindings.libusb_init_context(context_ptr, nil, 0))
      else
        Error.raise_on_error(FFIBindings.libusb_init(context_ptr))
      end

      @ptr = context_ptr.read_pointer
      @closed = false
      @hotplug_callbacks = {}
      @pollfd_notifiers = {}

      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr))

      options.each do |option, value|
        set_option(option, value)
      end
    end

    def close
      return if closed?

      ObjectSpace.undefine_finalizer(self)
      @hotplug_callbacks.keys.each { |handle| deregister_hotplug(handle) }
      FFIBindings.libusb_exit(@ptr)
      @ptr = FFI::Pointer::NULL
      @closed = true
    end

    def closed?
      @closed || @ptr.nil? || @ptr.null?
    end

    def devices(vendor_id: nil, product_id: nil, device_class: nil)
      all = raw_device_list
      all.select! { |device| device.vendor_id == vendor_id } unless vendor_id.nil?
      all.select! { |device| device.product_id == product_id } unless product_id.nil?
      all.select! { |device| device.device_class == device_class } unless device_class.nil?
      all
    end

    def open_device(vendor_id:, product_id:)
      handle_ptr = FFIBindings.libusb_open_device_with_vid_pid(@ptr, vendor_id, product_id)
      return nil if handle_ptr.null?

      handle = DeviceHandle.new(handle_ptr)
      return handle unless block_given?

      begin
        yield handle
      ensure
        handle.close
      end
    end

    def set_option(option, value = nil)
      normalized_option = normalize_option(option)

      if FFIBindings.function_available?(:libusb_set_option)
        result =
          if value.nil?
            FFIBindings.libusb_set_option(@ptr, normalized_option)
          else
            FFIBindings.libusb_set_option(@ptr, normalized_option, :int, value)
          end

        Error.raise_on_error(result)
      elsif normalized_option == OPTION_LOG_LEVEL && !value.nil?
        FFIBindings.libusb_set_debug(@ptr, value)
      else
        raise NotImplementedError, "libusb_set_option is not available"
      end
    rescue ArgumentError
      raise unless normalized_option == OPTION_LOG_LEVEL && !value.nil?

      FFIBindings.libusb_set_debug(@ptr, value)
    end

    def debug=(level)
      set_option(OPTION_LOG_LEVEL, level)
    end

    def has_capability?(capability)
      FFIBindings.libusb_has_capability(capability) != 0
    end

    def to_ptr
      @ptr
    end

    private

    def raw_device_list
      list_ptr = FFI::MemoryPointer.new(:pointer)
      count = Error.raise_on_error(FFIBindings.libusb_get_device_list(@ptr, list_ptr))
      base_ptr = list_ptr.read_pointer

      Array.new(count) do |index|
        device_ptr = base_ptr.get_pointer(index * FFI::Pointer.size)
        Device.new(self, device_ptr)
      end
    ensure
      if defined?(base_ptr) && base_ptr && !base_ptr.null?
        FFIBindings.libusb_free_device_list(base_ptr, 1)
      end
    end

    def normalize_option(option)
      case option
      when :log_level then OPTION_LOG_LEVEL
      when :use_usbdk then OPTION_USE_USBDK
      when :no_device_discovery then OPTION_NO_DEVICE_DISCOVERY
      when :log_callback then OPTION_LOG_CB
      else
        option
      end
    end
  end
end
