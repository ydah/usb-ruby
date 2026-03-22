# frozen_string_literal: true

module USB
  class Error < StandardError
    attr_reader :code

    ERROR_CLASSES = {}.freeze

    class << self
      def raise_on_error(result)
        raise class_for_code(result).new(result) if result.is_a?(Integer) && result.negative?

        result
      end

      def class_for_code(code)
        self::ERROR_CLASSES.fetch(code, self)
      end

      def libusb_error_name(code)
        FFIBindings.libusb_error_name(code)
      rescue StandardError
        code.to_s
      end

      def libusb_error_description(code)
        FFIBindings.libusb_strerror(code)
      rescue StandardError
        "libusb error #{code}"
      end
    end

    def initialize(code)
      @code = code
      super("#{self.class.libusb_error_name(code)}: #{self.class.libusb_error_description(code)}")
    end
  end

  class TransferError < Error
  end

  class IOError < Error
  end

  class InvalidParamError < Error
  end

  class AccessError < Error
  end

  class NoDeviceError < Error
  end

  class NotFoundError < Error
  end

  class BusyError < Error
  end

  class TimeoutError < Error
  end

  class OverflowError < Error
  end

  class PipeError < Error
  end

  class InterruptedError < Error
  end

  class NoMemError < Error
  end

  class NotSupportedError < Error
  end

  Error.send(:remove_const, :ERROR_CLASSES)
  Error::ERROR_CLASSES = {
    LIBUSB_ERROR_IO => IOError,
    LIBUSB_ERROR_INVALID_PARAM => InvalidParamError,
    LIBUSB_ERROR_ACCESS => AccessError,
    LIBUSB_ERROR_NO_DEVICE => NoDeviceError,
    LIBUSB_ERROR_NOT_FOUND => NotFoundError,
    LIBUSB_ERROR_BUSY => BusyError,
    LIBUSB_ERROR_TIMEOUT => TimeoutError,
    LIBUSB_ERROR_OVERFLOW => OverflowError,
    LIBUSB_ERROR_PIPE => PipeError,
    LIBUSB_ERROR_INTERRUPTED => InterruptedError,
    LIBUSB_ERROR_NO_MEM => NoMemError,
    LIBUSB_ERROR_NOT_SUPPORTED => NotSupportedError,
    LIBUSB_ERROR_OTHER => Error
  }.freeze
end
