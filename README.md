# usb-ruby

`usb-ruby` is a Ruby FFI binding for libusb 1.0. It exposes the libusb API through the top-level `USB` module and does not require native extension compilation.

## Installation

Add the gem to your Gemfile:

```bash
bundle add usb-ruby
```

Or install it directly:

```bash
gem install usb-ruby
```

## Usage

```ruby
require "usb"

USB::Context.open do |context|
  context.devices.each do |device|
    descriptor = device.device_descriptor
    puts format("%03d/%03d %04x:%04x",
                device.bus_number,
                device.device_address,
                descriptor.vendor_id,
                descriptor.product_id)
  end
end
```

## Development

Run:

```bash
bundle install
bundle exec rspec
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
