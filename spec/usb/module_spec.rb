# frozen_string_literal: true

RSpec.describe USB do
  it "has a version number" do
    expect(USB::VERSION).not_to be_nil
  end

  it "delegates device enumeration to a context" do
    fake_devices = [:device]
    context = instance_double(USB::Context, devices: fake_devices, close: nil)

    allow(USB::Context).to receive(:open).and_yield(context)

    expect(USB.devices).to eq(fake_devices)
  end

  it "returns the libusb version when bindings are available" do
    version_struct = instance_double(USB::FFIBindings::VersionStruct)
    pointer = instance_double(FFI::Pointer, null?: false)

    allow(USB::FFIBindings).to receive(:ensure_loaded!)
    allow(USB::FFIBindings).to receive(:libusb_get_version).and_return(pointer)
    allow(USB::FFIBindings::VersionStruct).to receive(:new).with(pointer).and_return(version_struct)
    allow(version_struct).to receive(:[]).with(:major).and_return(1)
    allow(version_struct).to receive(:[]).with(:minor).and_return(0)
    allow(version_struct).to receive(:[]).with(:micro).and_return(27)

    expect(USB.version).to eq("1.0.27")
  end
end
