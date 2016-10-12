require_relative "extensions/string" unless String.method_defined?(:underscore)
require_relative "aws_metadata/version"
require_relative "aws_metadata/instance_metadata"
require_relative "aws_metadata/cfn_stack_output"

module AWS
  module Metadata
    # For use in a Rails initializer to set the {.cfn_stack_name}, {.stub_responses} and {.cfn_dev_outputs_path}.
    #
    # @yield [self]
    # @return [void]
    # @example
    #
    #   AWS::Metadata.configure do |config|
    #     config.cfn_stack_name = 'your_cfn_stack_name' # As identified by the Stack Name column in the CloudFormation Section of the AWS console.
    #     config.stub_responses = Rails.env =~ /development|test/
    #     config.cfn_dev_outputs_path = 'path/to/cfn_dev_output.yml`
    #   end
    def self.configure
      yield self
      AWS::StackOutput.get unless disable_cfn_stack_output
    end

    # Set to true to return canned Instance responses and stubbed StackOutput responses from a cfn_dev_output.yml file.
    #
    # @param stub_responses [Boolean]
    # @return [Boolean]
    def self.stub_responses=(stub_responses = false)
      @stub_responses = stub_responses
    end

    # The flag whether or not to return canned Instance responses and stubbed StackOutput responses from a cfn_dev_output.yml file.
    #
    # @param stub_responses [Boolean]
    # @return [Boolean]
    def self.stub_responses
      @stub_responses
    end

    # Set to true to disable the AWS::StackOutput object and prevent it from loading.
    #
    # @param disable_cfn_stack_output [Boolean]
    # @return [Boolean]
    def self.disable_cfn_stack_output=(disable_cfn_stack_output = false)
      @disable_cfn_stack_output = disable_cfn_stack_output
    end

    # The flag whether or not to disable the AWS::StackOutput object and prevent it from loading.
    #
    # @param stub_responses [Boolean]
    # @return [Boolean]
    def self.disable_cfn_stack_output
      @disable_cfn_stack_output
    end

    # Set the stack name as identified by the Stack Name column in the CloudFormation Section of the AWS console.
    #
    # @param stack_name
    # @return [String]
    def self.cfn_stack_name=(stack_name)
      @stack_name = stack_name
    end

    # The stack name as identified by the Stack Name column in the CloudFormation Section of the AWS console.
    #
    # @return [String]
    def self.cfn_stack_name
      @stack_name
    end

    # Set the path to the aws_identity_stubs.yml
    #
    # Only needs to be set if {.stub_responses} is set to true.
    #
    # @return [String]
    def self.aws_identity_stubs_path=(aws_identity_stubs_path)
      @aws_identity_stubs_path = aws_identity_stubs_path
    end

    # Set the path to the aws_identity_stubs.yml
    #
    # Defaults to the config directory in a Rails application, or the file in tests/fixtures/aws_identity_stubs.yml if not in a Rails app.
    #
    # @return [String]
    def self.aws_identity_stubs_path
      @aws_identity_stubs_path ||= defined?(Rails) ? Rails.root.join('config') : File.expand_path(File.dirname(__FILE__) + '/../test/fixtures')
    end

    # Set the path to the cfn_dev_output.yml file with the keys you have defined as Outputs for your Cloud Formation stack.
    #
    # Only needs to be set if {.stub_responses} is set to true.
    #
    # @return [String]
    def self.cfn_dev_outputs_path=(dev_outputs_path)
      @dev_outputs_path = dev_outputs_path
    end

    # Set the path to the cfn_dev_output.yml file with the keys you have defined as Outputs for your Cloud Formation stack.
    #
    # Defaults to the config directory in a Rails application.
    #
    # @return [String]
    def self.cfn_dev_outputs_path
      @dev_outputs_path ||= defined?(Rails) ? Rails.root.join('config') : ''
    end
  end
end
