require 'spec_helper'

describe VagrantWindows::Config::Windows , :unit => true do
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

  describe "overriding defaults" do
    [:halt_timeout, :halt_check_interval].each do |attribute|
      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, 10)
        instance.finalize!
        instance.send(attribute).should == 10
      end
    end
  end

  describe '.validate' do

    let(:machine) do 
      machine = mock(Vagrant::Machine) 
      machine.stub!(:config).and_return do
        windows = VagrantWindows::Config::Windows.new
        windows.hault_timeout = ''
        windows.hault_check_interval = ''
        windows.set_work_network = ''
        OpenStruct.new(:windows => windows )
      end
      machine
    end

    context 'without errors' do
      it { instance.validate(machine).should == {"Windows Guest" => []} }
    end
     # TODO: Add checking for objects with errors

  end
end




describe VagrantWindows::Config::WinRM ,:unit => true do
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
    its("max_tries")  { should == 20 }
    its("timeout")    { should == 1800 }
  end

  describe "overriding defaults" do
    [:username, :password, :host, :port, :guest_port, :max_tries, :timeout].each do |attribute|
      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, 10)
        instance.finalize!
        instance.send(attribute).should == 10
      end
    end
  end
end
