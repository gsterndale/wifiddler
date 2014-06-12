require 'spec_helper'

describe "CLI" do
  let(:io)   { StringIO.new }
  let(:args) { ['--interval', '0.00001', '--timeout', '0.001', '--verbose'] }
  let(:cli)  { WiFiddler::CLI.run(io, args) }

  def stub_any_command_output(output)
    WiFiddler::CLI.any_instance.stub(:system) do |command, options|
      options[:out].write output
    end
  end

  describe "output" do
    subject do
      cli
      io.string
    end

    context "connected to a network" do
      before do
        stub_any_command_output "Current Wi-Fi Network: Karma Wi-Fi"
      end

      it { should match /connected/i }
    end

    context "not connected to a network" do
      before do
        stub_any_command_output "You are not associated with an AirPort network."
      end
      it { should match /unable to establish connection/i }
    end

    context "taking too long" do
      let(:args) { ['--interval', '10', '--timeout', '0.0001', '--verbose'] }
      before do
        stub_any_command_output "You are not associated with an AirPort network."
      end
      it { should match /unable to establish connection after 0.0001 seconds/i }
    end

    context "taking too many attempts" do
      let(:args) { ['--interval', '0.0001', '--timeout', '2', '--attempts', '2', '--verbose'] }
      before do
        stub_any_command_output "You are not associated with an AirPort network."
      end
      it { should match /unable to establish connection after 2 attempts/i }
    end
  end

  describe "status code" do
    subject { cli }

    context "connected to a network" do
      before do
        stub_any_command_output "Current Wi-Fi Network: Karma Wi-Fi"
      end

      it { should be 0 }
    end

    context "not connected to a network" do
      before do
        stub_any_command_output "You are not associated with an AirPort network."
      end
      it { should be 1 }
    end
  end
end
