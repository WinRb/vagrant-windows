require 'spec_helper'

describe VagrantWindows::Config::WinRM, :unit => true do
  let(:instance) { described_class.new }

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("username")   { should == "vagrant" }
    its("password")   { should == "vagrant" }
    its("host")       { should == nil }
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
