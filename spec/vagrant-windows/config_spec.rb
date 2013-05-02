require "vagrant-windows/config/windows"
require "vagrant-windows/config/winrm"

describe VagrantWindows::Config::Windows do
  let(:instance) { described_class.new }

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("halt_timeout")        { should == 30 }
    its("halt_check_interval") { should == 1 }
  end
end


describe VagrantWindows::Config::WinRM do
  let(:instance) { described_class.new }

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("username")   { should == "vagrant" }
    its("password")   { should == "vagrant" }
    its("host")       { should == "localhost" }
    its("port")       { should == 5985 }
    its("guest_port") { should == 5985 }
    its("max_tries")  { should == 12 }
    its("timeout")    { should == 1800 }
  end
end
