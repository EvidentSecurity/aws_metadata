# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_metadata/version'

Gem::Specification.new do |spec|
  spec.name    = "aws_metadata"
  spec.version = AwsCfnStackOutput::VERSION
  spec.authors = ['Evident.io']
  spec.email   = ['support@evident.io']

  spec.summary  = %q{Gem to provide the Instance Metadata and Cloud Formation template outputs.}
  spec.homepage = "https://git.int.evident.io/full-stack/aws-metadata"


  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency 'aws-sdk'
end
