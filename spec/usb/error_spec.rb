# frozen_string_literal: true

RSpec.describe USB::Error do
  before do
    allow(USB::FFIBindings).to receive(:libusb_error_name).and_return("LIBUSB_ERROR_IO")
    allow(USB::FFIBindings).to receive(:libusb_strerror).and_return("input/output error")
  end

  it "raises a mapped subclass for negative results" do
    expect { described_class.raise_on_error(USB::LIBUSB_ERROR_IO) }.to raise_error(USB::IOError)
  end

  it "passes through non-negative results" do
    expect(described_class.raise_on_error(7)).to eq(7)
  end

  it "falls back to generic error text when libusb error helpers are unavailable" do
    allow(USB::FFIBindings).to receive(:libusb_error_name).and_raise(LoadError, "libusb missing")
    allow(USB::FFIBindings).to receive(:libusb_strerror).and_raise(LoadError, "libusb missing")

    expect { described_class.raise_on_error(USB::LIBUSB_ERROR_BUSY) }
      .to raise_error(USB::BusyError, "-6: libusb error -6")
  end
end
