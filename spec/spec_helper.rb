require 'simplecov'
SimpleCov.start

require 'bundler'
Bundler.setup
Bundler.require

require "vagrant-windows/config/windows"
require "vagrant-windows/config/winrm"
require "vagrant-windows/communication/guestnetwork"
require "vagrant-windows/communication/winrmshell"
require "vagrant-windows/helper"


