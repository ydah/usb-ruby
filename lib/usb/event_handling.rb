# frozen_string_literal: true

module USB
  module EventHandling
    def handle_events(timeout: nil)
      if timeout.nil?
        Error.raise_on_error(FFIBindings.libusb_handle_events(@ptr))
      else
        timeval = build_timeval(timeout)
        Error.raise_on_error(FFIBindings.libusb_handle_events_timeout(@ptr, timeval.pointer))
      end
    end

    def handle_events_completed(completed: nil, timeout: nil)
      completed_ptr = completed_pointer(completed)

      if timeout.nil?
        Error.raise_on_error(FFIBindings.libusb_handle_events_completed(@ptr, completed_ptr))
      else
        timeval = build_timeval(timeout)
        Error.raise_on_error(FFIBindings.libusb_handle_events_timeout_completed(@ptr, timeval.pointer, completed_ptr))
      end
    end

    def handle_events_locked(timeout: nil)
      timeval = build_timeval(timeout)
      Error.raise_on_error(FFIBindings.libusb_handle_events_locked(@ptr, timeval&.pointer || FFI::Pointer::NULL))
    end

    def try_lock_events
      result = FFIBindings.libusb_try_lock_events(@ptr)
      Error.raise_on_error(result) if result.negative?
      result.zero?
    end

    def lock_events
      FFIBindings.libusb_lock_events(@ptr)
      self
    end

    def unlock_events
      FFIBindings.libusb_unlock_events(@ptr)
      self
    end

    def event_handling_ok?
      FFIBindings.libusb_event_handling_ok(@ptr) != 0
    end

    def event_handler_active?
      FFIBindings.libusb_event_handler_active(@ptr) != 0
    end

    def lock_event_waiters
      FFIBindings.libusb_lock_event_waiters(@ptr)
      self
    end

    def unlock_event_waiters
      FFIBindings.libusb_unlock_event_waiters(@ptr)
      self
    end

    def wait_for_event(timeout: nil)
      timeval = build_timeval(timeout)
      Error.raise_on_error(FFIBindings.libusb_wait_for_event(@ptr, timeval&.pointer || FFI::Pointer::NULL))
    end

    def interrupt_event_handler
      FFIBindings.libusb_interrupt_event_handler(@ptr)
      self
    end

    def pollfds
      pollfd_ptr = FFIBindings.libusb_get_pollfds(@ptr)
      return [] if pollfd_ptr.null?

      pollfds = []
      index = 0

      loop do
        entry_ptr = pollfd_ptr.get_pointer(index * FFI::Pointer.size)
        break if entry_ptr.null?

        pollfds << Pollfd.new(entry_ptr)
        index += 1
      end

      pollfds
    ensure
      FFIBindings.libusb_free_pollfds(pollfd_ptr) if defined?(pollfd_ptr) && pollfd_ptr && !pollfd_ptr.null?
    end

    def next_timeout
      timeval = FFIBindings::TimevalStruct.new(FFI::MemoryPointer.new(FFIBindings::TimevalStruct))
      result = FFIBindings.libusb_get_next_timeout(@ptr, timeval.pointer)
      Error.raise_on_error(result) if result.negative?
      return nil if result.zero?

      timeval[:tv_sec] + (timeval[:tv_usec] / 1_000_000.0)
    end

    def pollfds_handle_timeouts?
      FFIBindings.libusb_pollfds_handle_timeouts(@ptr) != 0
    end

    def set_pollfd_notifiers(added:, removed:)
      added_callback = FFI::Function.new(:void, [:int, :short, :pointer]) do |fd, events, _user_data|
        added&.call(Pollfd.from_values(fd, events))
      end

      removed_callback = FFI::Function.new(:void, [:int, :pointer]) do |fd, _user_data|
        removed&.call(fd)
      end

      @pollfd_notifiers[:added] = added_callback
      @pollfd_notifiers[:removed] = removed_callback
      FFIBindings.libusb_set_pollfd_notifiers(@ptr, added_callback, removed_callback, nil)
      self
    end

    private

    def build_timeval(timeout)
      return nil if timeout.nil?

      seconds = timeout.to_f
      timeval = FFIBindings::TimevalStruct.new(FFI::MemoryPointer.new(FFIBindings::TimevalStruct))
      timeval[:tv_sec] = seconds.floor
      timeval[:tv_usec] = ((seconds - seconds.floor) * 1_000_000).round
      timeval
    end

    def completed_pointer(completed)
      case completed
      when nil
        FFI::Pointer::NULL
      when FFI::Pointer
        completed
      else
        pointer = FFI::MemoryPointer.new(:int)
        pointer.write_int(completed ? 1 : 0)
        pointer
      end
    end
  end

  Context.include(EventHandling)
end
