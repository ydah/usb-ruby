# frozen_string_literal: true

module USB
  class IsoPacket
    def initialize(transfer, struct)
      @transfer = transfer
      @struct = struct
    end

    def length
      @struct[:length]
    end

    def length=(value)
      @struct[:length] = value
    end

    def actual_length
      @struct[:actual_length]
    end

    def status
      @struct[:status]
    end
  end
end
