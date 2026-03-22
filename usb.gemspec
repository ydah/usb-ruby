# frozen_string_literal: true

require_relative "lib/usb/version"

Gem::Specification.new do |spec|
  spec.name = "usb-ruby"
  spec.version = USB::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Ruby FFI bindings for libusb 1.0"
  spec.description = "usb-ruby provides idiomatic Ruby access to libusb 1.0 via FFI without native extensions."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
