require 'spec_helper'

describe VagrantWindows, :unit => true do
  describe '#vagrant_windows_root' do
    subject { VagrantWindows.vagrant_windows_root.to_s }
    it { should_not =~ /spec/ }
    it { should == Bundler.root.to_s }
  end

  describe '#load_script' do
    scripts = Dir["#{Bundler.root.to_s}/lib/vagrant-windows/scripts/**"].
      select { |f| File.file?(f) }.
      collect{ |f| File.basename(f) }

    scripts.each do |script|
      describe script do
        it { VagrantWindows.load_script(script).should_not be_empty }
        it { VagrantWindows.load_script(script).should be_a(String) }
      end
    end
  end

  describe '#load_script_template' do
    templates = Dir["#{Bundler.root.to_s}/lib/vagrant-windows/scripts/*.erb"].
      select { |f| File.file?(f) }.
      collect{ |f| File.basename(f,'.erb') }

    templates.each do |template|
      describe template do
        it { VagrantWindows.load_script_template(template, :options => {}) }
      end
    end
  end

  describe '#expand_script_path' do
    subject { VagrantWindows.expand_script_path('testfile').to_s }
    it { should == "#{Bundler.root.to_s}/lib/vagrant-windows/scripts/testfile"}
  end
end
