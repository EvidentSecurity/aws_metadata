require 'yaml'

module AWS
  # @note Dynamic methods are generated from the underscored value of the Output Keys.
  module StackOutput

    # Makes the call to get the Stack Template's Outputs and dynamically creates methods for each Output.
    def self.get
      stack_outputs.each do |o|
        (
        class << StackOutput;
          self
        end).class_eval do
          define_method(o.output_key.to_s.underscore.to_sym) { o.output_value }
        end
      end
    end

    private_class_method

    # @private
    def self.client
      @client ||= Aws::CloudFormation::Client.new(region: AWS::Instance.dynamic.instance_identity.document.region, stub_responses: AWS::Metadata.stub_responses)
    end

    # @private
    def self.stack
      @stack ||= client.describe_stacks(stack_name: AWS::Metadata.cfn_stack_name).first.stacks.first
    end

    # @private
    def self.stack_outputs
      @outputs ||= AWS::Metadata.stub_responses ? dev_outputs : stack.outputs
    end

    # @private
    def self.dev_outputs
      require 'erb'
      output        = Struct.new(:output_key, :output_value)
      yaml          = Pathname.new(File.join(AWS::Metadata.cfn_dev_outputs_path, 'cfn_dev_output.yml'))
      output_values = YAML.load(ERB.new(yaml.read).result)
      [].tap do |a|
        output_values.each do |key, value|
          a << output.new(key, value)
        end
      end
    rescue
      puts "#{yaml} not found AWS::StackOutput will not be available."
      []
    end
  end
end
