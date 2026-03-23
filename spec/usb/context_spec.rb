# frozen_string_literal: true

RSpec.describe USB::Context do
  let(:context_ptr) { instance_double(FFI::Pointer, null?: false) }
  let(:pointer_ptr) { instance_double(FFI::MemoryPointer, read_pointer: context_ptr) }

  before do
    allow(USB::FFIBindings).to receive(:ensure_loaded!)
    allow(USB::FFIBindings).to receive(:function_available?).and_return(false)
    allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(pointer_ptr)
    allow(USB::FFIBindings).to receive(:libusb_init).with(pointer_ptr).and_return(USB::LIBUSB_SUCCESS)
    allow(USB::FFIBindings).to receive(:libusb_exit)
    allow(USB::FFIBindings).to receive(:libusb_set_debug)
  end

  it "closes the context in block form" do
    yielded = nil

    described_class.open do |context|
      yielded = context
      expect(context).not_to be_closed
    end

    expect(USB::FFIBindings).to have_received(:libusb_exit).with(context_ptr)
    expect(yielded).to be_closed
  end

  it "accepts direct keyword options" do
    context = described_class.new(log_level: USB::LOG_LEVEL_INFO)

    expect(USB::FFIBindings).to have_received(:libusb_set_debug).with(context_ptr, USB::LOG_LEVEL_INFO)

    context.close
  end
end
