# Original code from https://github.com/airbnb/gem-aws-Instance
# It's just a single file so eliminate the dependency by putting it in the repo directly and add parsing for the document object.
# Also added response stubs
require 'net/http'

module AWS
  module Instance
    def self.metadata(path: nil, version: 'latest', host: '169.254.169.254', port: '80')
      load_stubs
      url_prefix = "/#{version}/meta-data/"
      if path.nil?
        @metadata ||= Treeish.new http(host, port), url_prefix
        raise 'no metadata' if @metadata.blank? # There should always be metadata
        @metadata
      else
        @metadata_path       ||= Hashish.new
        @metadata_path[path] ||= value_by_path(path, @metadata) do
          query(http(host, port), "#{url_prefix}#{path}")
        end
      end
    end

    def self.user_data(version: 'latest', host: '169.254.169.254', port: '80')
      load_stubs
      @user_data ||= query(http(host, port), "/#{version}/user-data")
    end

    def self.dynamic(path: nil, version: 'latest', host: '169.254.169.254', port: '80')
      load_stubs
      url_prefix = "/#{version}/dynamic/"
      if path.nil?
        @dynamic ||= Treeish.new http(host, port), url_prefix
      else
        @dynamic_path       ||= Hashish.new
        @dynamic_path[path] ||= value_by_path(path, @dynamic) do
          query(http(host, port), "#{url_prefix}#{path}")
        end
      end
    end

    # All the metadata from 169.254.169.254
    #
    # The hashes are Hashish objects that allows regular method like calls where all method names are the keys underscored.
    def self.to_hash
      { :metadata => metadata.merge(Hash(@metadata_path)), :user_data => user_data, :dynamic => dynamic.merge(Hash(@dynamic_path)) }
    end

    # Can't be the first one to make that pun.
    # Still proud.
    # @private
    class Hashish < Hash
      def initialize(hash = {})
        hash.each do |key, value|
          self[key.to_s.underscore.gsub('_', '-')] = value.is_a?(Hash) ? Hashish.new(value) : value
        end
      end

      def method_missing(name)
        attr       = name.to_s.gsub('_', '-')
        self[attr] = self[attr].call if self[attr].is_a?(Proc)
        self[attr]
      end
    end

    # @private
    class Treeish < Hashish
      private
      def initialize(http, prefix)
        entries = Instance.query(http, prefix)
        entries.lines.each do |l|
          l.chomp!
          if l.end_with? '/'
            self[l[0..-2]] = Proc.new { Treeish.new http, "#{prefix}#{l}" }
            # meta-data/public-keys/ entries have a '0=foo' format
          elsif l =~ /(\d+)=(.*)/
            number, name = $1, $2
            self[name]   = Proc.new { Treeish.new http, "#{prefix}#{number}/" }
          else
            self[l] = Proc.new { Instance.query(http, "#{prefix}#{l}") }
          end
        end
      end
    end


    # @private
    def self.http(host, port)
      @http ||= Net::HTTP.new host, port
    end
    private_class_method :http

    # @private
    def self.query(http, path)
      tries ||= 1
      rep   = http.request Net::HTTP::Get.new path
      raise "bad request: #{path}" unless Net::HTTPOK === rep
      value = JSON.parse(rep.body)
      value.is_a?(Hash) ? Hashish.new(value) : value
    rescue JSON::ParserError
      rep.body
    rescue
      return '' if tries >= 10
      sleep 1
      tries += 1
      retry
    end
    private_class_method :query

    # Helper method to provide "stubs" for non aws environments, ie. development and test
    # @private
    def self.load_stubs
      return unless AWS::Metadata.stub_responses && @metadata.nil?
      @yaml                                     ||= Pathname.new(File.join(AWS::Metadata.aws_identity_stubs_path, 'aws_identity_stubs.yml'))
      @responses                                ||= YAML.load(ERB.new(@yaml.read).result)
      @metadata                                 ||= Hashish.new @responses[:metadata]
      @user_data                                ||= @responses[:user_data]
      @dynamic                                  ||= Hashish.new @responses[:dynamic]
    end
    private_class_method :load_stubs

    def self.value_by_path(path, obj)
      if AWS::Metadata.stub_responses
        path.split('/').inject(obj) do |o, method|
          o.send method.to_s.underscore
        end
      else
        yield
      end
    end
    private_class_method :value_by_path
  end
end
