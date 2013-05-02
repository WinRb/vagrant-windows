require "vagrant-windows/config/windows"

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
