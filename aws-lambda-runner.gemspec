# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'aws-lambda-runner'
  s.version     = '1.0.0'
  s.date        = '2015-01-09'
  s.summary     = 'AWS Lambda testing helper'
  s.description = 'Trigger AWS Lambda functions without deploying to AWS'
  s.homepage    = 'https://github.com/bbc/aws-lambda-runner'
  s.license = 'Apache 2'
  s.authors     = ['andrew wheat', 'tristan hill']
  s.email       = []

  s.files       = Dir['lib/**/*.rb', 'lib/*.json', 'js/*.json', 'js/*.js']

  s.test_files  = %w( )

  s.require_paths = ['lib']

  s.add_dependency 'process-helper', '~> 1'
  s.add_dependency 'rest-client', '~> 1.0'
  s.add_dependency 'file_utils', '~> 1'
  s.add_development_dependency 'rubocop', '~> 0'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 10.0'
end
