# AWS Metadata

AWS::Metadata has 2 components to it.  `AWS::Instance` and `AWS::StackOutput`

This first, `AWS::Instance`, is mostly identical to https://github.com/airbnb/gem-aws-instmd and exposes the instance metadata information through a Ruby API.

The second, `AWS::StackOutput`, gives you access to the Cloud Formation Outputs you define in your CFN template given a template name. Usage of `AWS::StackOuput` requires installing and requiring the CloudFormation SDK.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_metadata'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_metadata

## Usage for `AWS::Instance`

```ruby
puts AWS::Instance.metadata.instance_id
puts AWS::Instance.dynamic.instance_identity.document.account_id
puts AWS::Instance.user_data
```

AWS::Instance is lazy loaded and only makes calls to 169.254.169.254 for the paths requested.  In other words, the entire
object hierarchy is not built at once, thereby reducing the total number of HTTP requests and reducing the chance
of being throttled by AWS.

You can alternatively pass the relative endpoint to `metadata` and `dynamic`

```ruby
puts AWS::Instance.metadata(path: 'instance-id')
puts AWS::Instance.dynamic(path: 'instance-identity/document').account_id
```

This has the added benefit of reducing the number of HTTP calls even further if needed/desired.  For instance `AWS::Instance.metadata.instance_id`
will make 2 calls, 1 for `/meta-data` and another for `meta-data/instance-id`, where `AWS::Instance.metadata(path: 'instance-id')`
will only make a single call to `/meta-data/instance-id`.

All calls are cached.

Calls are retried upto 10 times in 1 second intervals if a 200 response is not received.

To return stubbed responses, you can add this to an initializer:

```ruby
AWS::Metadata.configure do |config|
  config.stub_responses = Rails.env =~ /development|test/
end
```

or

```ruby
AWS::Metadata.stub_responses = Rails.env =~ /development|test/
```

This will prevent HTTP calls to 169.254.169.254 and return canned results.

If you have `stub_responses` set to true, you can create a `aws_identity_stubs.yml` file with the data you want returned.
By default, the gem will look for `aws_identity_stubs.yml` in the `config` directory of a Rails app.
If you don't setup your own `aws_identity_stubs.yml`, then the gem will use it's own found in test/fixtures/aws_identity_stubs.yml.  You can also use this file as a template for creating your own with custom data.
If you are not using this gem in a Rails app, then you need to specify the path in the initializer.

```ruby
AWS::Metadata.configure do |config|
  config.stub_responses = Rails.env =~ /development|test/
  config.aws_identity_stubs_path = 'path/to/aws_identity_stubs.yml'
end
```

or

```ruby
AWS::Metadata.stub_responses = Rails.env =~ /development|test/
AWS::Metadata.aws_identity_stubs_path = 'path/to/aws_identity_stubs.yml'
AWS::StackOutput.get
````

When stubbing responses, both `AWS::Instance` and `AWS::StackOutput` will be stubbed.

## Usage for `AWS::StackOutput`
You must first configure the gem in an initializer.

```ruby
AWS::Metadata.configure do |config|
  config.cfn_stack_name = 'your_cfn_stack_name' # As identified by the Stack Name column in the CloudFormation Section of the AWS console.
end
```

or

```ruby
AWS::Metadata.cfn_stack_name = 'your_cfn_stack_name'
AWS::StackOutput.get
```

Methods are dynamically generated from the Outputs that have been defined for the configured `cfn_stack_name`.
So if you have an output key of `S3BucketName` defined, you can get the value with

```ruby
puts AWS::StackOutput.s3_bucket_name
```

If you have `stub_responses` set to true, you will have to create a `cfn_dev_output.yml` file with the keys you have defined as Outputs for your Cloud Formation stack.
For example, to stub the response of a stack that has a key of `S3BucketName`, create a `cfn_dev_output.yml` file with the contents of:

```yaml
S3BucketName: my_unique_bucket_for_this_stack
```

By default, the gem will look for `cfn_dev_output.yml` in the `config` directory of a Rails app.  If you are not using this gem in a Rails app, then you need to specify the path in the initializer.

```ruby
AWS::Metadata.configure do |config|
  config.cfn_stack_name = 'your_cfn_stack_name' # As identified by the Stack Name column in the CloudFormation Section of the AWS console.
  config.stub_responses = Rails.env =~ /development|test/
  config.cfn_dev_outputs_path = 'path/to/cfn_dev_output.yml'
end
```

or

```ruby
AWS::Metadata.cfn_stack_name = 'your_cfn_stack_name'
AWS::Metadata.stub_responses = Rails.env =~ /development|test/
AWS::Metadata.cfn_dev_outputs_path = 'path/to/cfn_dev_output.yml'
AWS::StackOutput.get
```

The application user's role will need to be authorized to perform: cloudformation:DescribeStacks.

If the `AWS::StackOutput` object is not needed, then you can disable it.

```ruby
AWS::Metadata.configure do |config|
  config.disable_cfn_stack_output = true
end
```


## Differences between `AWS::InstMD` and `AWS::Instance`

The code for `AWS::Instance` is mostly a copy directly from the aws_instmd repo.  The only differences between `AWS::Instance` and `AWS::InstMD` are:

1. The class name.  We removed the MD(metadata) from the name since this gem also has the StackOutput namespace and it's all really metadata.
2. `AWS::InstMD.meta_data` to `AWS::Instance.metadata`.  We changed meta_data to metadata to be consistent with the naming in our SDK and APIs.
3. The `AWS::Instance.dynamic.instance_identity.document` returns a Hashish object you can call methods on, rather than a JSON document that has to be parsed manually into a hash. So `AWS::Instance.dynamic.instance_identity.document.account_id` just works.
4. We added the ability to have stubbed responses returned.  See the usage section above.

## Dependencies
 Ruby >= 2.0
 aws-sdk gem

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aws_metadata. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Thanks to https://github.com/airbnb for their aws_instmd gem.
