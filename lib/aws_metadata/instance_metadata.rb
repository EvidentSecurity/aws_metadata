# Original code from https://github.com/airbnb/gem-aws-Instance
# It's just a single file so eliminate the dependency by putting it in the repo directly and add parsing for the document object.
# Also added response stubs
require 'net/http'

module AWS
  class Instance
    # @private
    def self.method_missing name, *args, &block
      @@root ||= Instance.new
      @@root.method(name).call(*args, &block)
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

      def method_missing name
        if name.to_s == 'document'
          Hashish.new(JSON.parse(self['document']))
        else
          self[name.to_s.gsub('_', '-')]
        end
      end
    end

    # @private
    class Treeish < Hashish
      private
      def initialize http, prefix
        entries = Instance.query http, prefix
        entries.lines.each do |l|
          l.chomp!
          if l.end_with? '/'
            self[l[0..-2]] = Treeish.new http, "#{prefix}#{l}"
            # meta-data/public-keys/ entries have a '0=foo' format
          elsif l =~ /(\d+)=(.*)/
            number, name = $1, $2
            self[name]   = Treeish.new http, "#{prefix}#{number}/"
          else
            self[l] = Instance.query http, "#{prefix}#{l}"
          end
        end
      end
    end

    attr_accessor :user_data, :metadata, :dynamic

    # Amazon, Y U NO trailing slash entries
    # in /, /$version and /$version/dynamic/??
    # There is waaay too much code here.
    # @private
    def initialize version='latest', host='169.254.169.254', port='80'
      if AWS::Metadata.stub_responses
        load_stubs
        return
      end
      http       = Net::HTTP.new host, port
      @metadata = Treeish.new http, "/#{version}/meta-data/"
      @user_data = Instance.query http, "/#{version}/user-data"
      @dynamic   = Hashish.new

      begin
        dynamic_stuff = Instance.query(http, "/#{version}/dynamic/").lines
      rescue
        dynamic_stuff = []
      end
      dynamic_stuff.each do |e|
        e           = e.chomp.chomp '/'
        @dynamic[e] = Treeish.new http, "/#{version}/dynamic/#{e}/"
      end
    end

    # @private
    def self.query http, path
      rep = http.request Net::HTTP::Get.new path
      unless Net::HTTPOK === rep
        raise Net::HTTPBadResponse, "#{rep.code} #{path}"
      end
      rep.body
    end

    # Helper method to provide "stubs" for non aws deployments
    # @private
    def load_stubs
      yaml = Pathname.new(File.join(AWS::Metadata.aws_identity_stubs_path, 'aws_identity_stubs.yml'))
      responses = YAML.load(ERB.new(yaml.read).result)
      @metadata = Hashish.new responses[:metadata]
      @user_data = responses[:user_data]
      @dynamic = Hashish.new responses[:dynamic]
      @dynamic['instance-identity']['document'] = @dynamic['instance-identity']['document'].to_json
    end

    # All the metadata from 169.254.169.254
    #
    # The hashes are Hashish objects that allows regular method like calls where all method names are the keys underscored.
    def to_hash
      { :metadata => @metadata, :user_data => @user_data, :dynamic => @dynamic }
    end
  end
end
