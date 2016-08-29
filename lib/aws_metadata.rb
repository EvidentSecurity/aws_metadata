require_relative "extensions/string" unless String.method_defined?(:underscore)
require_relative "aws_metadata/version"
require_relative "aws_metadata/instance_metadata"
require_relative "aws_metadata/cfn_stack_output"

module AWS
  module Metadata
    def self.configure
      yield self
      AWS::StackOutput.get
    end

    def self.stub_responses=(stub_responses = false)
      @stub_responses = stub_responses
    end

    def self.stub_responses
      @stub_responses
    end

    def self.cfn_stack_name=(stack_name)
      @stack_name = stack_name
    end

    def self.cfn_stack_name
      @stack_name
    end

    def self.cfn_dev_outputs_path=(dev_outputs_path)
      @dev_outputs_path = dev_outputs_path
    end

    def self.cfn_dev_outputs_path
      @dev_outputs_path ||= defined?(Rails) ? Rails.root.join('config') : ''
    end
  end
end
