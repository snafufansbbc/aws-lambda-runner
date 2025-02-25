require 'process-helper'
require 'rest-client'
require 'json'
require 'English'
require 'fileutils'

def load_json(name)
  File.open(File.join(File.dirname(__FILE__), name)) { |file| return JSON.load(file) }
end

# runs a nodejs lambda program so the s3 events can be sent to it via http post
module LambdaRunner
  # abstract for running the program
  class Runner
    def initialize(module_path, name)
      @module_path = module_path
      @name = name
      @port = 8897
    end

    def install_deps
      @npm_cwd = File.expand_path('../../js/', __FILE__)
      STDOUT.puts("trying to use npm install in #{@npm_cwd}")
      npm_install_pid = spawn('npm', 'install', chdir: @npm_cwd)
      Process.wait(npm_install_pid)
      fail 'failed to install the lambda startup' if ($CHILD_STATUS.exitstatus != 0)
    end

    def add_aws_sdk
      STDOUT.puts("Copying aws-sdk into the lambda function's node_modules.")
      # cp -r File.expand_path(../../js/node_modules/aws-sdk, __FILE__) $(dirname @module_path)/node_modules
      FileUtils.cp_r File.expand_path('../../js/node_modules/aws-sdk', __FILE__), "#{File.dirname(@module_path)}/node_modules"
    end

    def start(opts = { cover: true })
      if opts[:timeout] == nil
        opts[:timeout] = '30000'
      end
      install_deps
      add_aws_sdk
      # start node in a way that emulates how it's run in production
      cmd = ['node']
      cmd = [File.join(@npm_cwd, 'node_modules/.bin/istanbul'), 'cover', '--root', File.dirname(@module_path), '--'] if opts[:cover]
      cmd += [File.join(@npm_cwd, 'startup.js'), '-p', @port.to_s, '-m', @module_path, '-h', @name, '-t', opts[:timeout]]
      @proc = ProcessHelper::ProcessHelper.new(print_lines: true)
      @proc.start(cmd, 'Server running at http')
    end

    def url
      "http://localhost:#{@port}/"
    end

    def wait(response)
      case response.code
      when 201 then false
      when 200 then true
      when 504 then fail 'timeout'
      when 502 then fail response
      else fail "unknown response #{response.code}"
      end
    end

    def send(message)
      id = RestClient.post(url, message, content_type: :json).to_str
      loop do
        wait(RestClient.get(url, params: { id: id })) && break
        sleep(0.1)
      end
    end

    def stop
      RestClient.delete(url)
    end
  end

  # aws events
  class Events
    def self.s3_event(bucket, key, local_path)
      event = load_json('sample_req.json')
      event['Records'].each do |record|
        record['file'] = { 'path' => local_path }
        record['s3']['bucket'].update('name' => bucket,
                                      'arn' => 'arn:aws:s3:::' + bucket)
        record['s3']['object']['key'] = key
        record
      end
      event.to_json
    end

    def self.sns_event(topicArn, messageId, timestamp, messageBody)
      event = load_json('sample_sns_req.json')
      event['Records'].each do |record|
        record['Sns']['topicArn'] = topicArn
        record['Sns']['messageId'] = messageId
        record['Sns']['timestamp'] = timestamp
        record['Sns']['messageBody'] = messageBody
      end
      event.to_json
    end
  end
end

# vi: tabstop=2:softtabstop=2:shiftwidth=2:expandtab
