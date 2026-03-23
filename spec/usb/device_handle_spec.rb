# frozen_string_literal: true

RSpec.describe USB::DeviceHandle do
  let(:handle_ptr) { FFI::Pointer.new(0x1000) }

  before do
    allow(USB::FFIBindings).to receive(:libusb_close)
    allow(USB::FFIBindings).to receive(:libusb_claim_interface).and_return(USB::LIBUSB_SUCCESS)
    allow(USB::FFIBindings).to receive(:libusb_release_interface).and_return(USB::LIBUSB_SUCCESS)
  end

  it "releases an interface after yielding" do
    handle = described_class.new(handle_ptr)

    handle.with_interface(1) { |value| expect(value).to eq(handle) }

    expect(USB::FFIBindings).to have_received(:libusb_release_interface).with(handle_ptr, 1)

    handle.close
  end

  it "does not release an interface when claiming fails" do
    handle = described_class.new(handle_ptr)
    allow(USB::FFIBindings).to receive(:libusb_claim_interface).and_return(USB::LIBUSB_ERROR_BUSY)

    expect { handle.with_interface(1) { nil } }.to raise_error(USB::BusyError)
    expect(USB::FFIBindings).not_to have_received(:libusb_release_interface)

    handle.close
  end
end
