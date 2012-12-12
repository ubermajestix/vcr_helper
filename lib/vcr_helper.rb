require "vcr_helper/version"

module VcrHelper
  #
  # Must be included after #setup and #teardown have been defined.
  #
  # Pass VR=true to a test or rake to open network connectivity and re-record all requests and responses
  # Otherwise, blocks all network connectivity and uses cassettes to replay requests and responses.
  # 
  # Stores all cassettes in test/vcr_cassettes.
  # Each test case is saved to a different file.
  #

  def record?
    ENV['VR']
  end

  def cassette_name
    if self.respond_to?(:described_class)
      self.described_class.to_s.underscore.gsub('/','_') + '__' + self.example.metadata[:description_args].first.strip.downcase.squeeze(' ').gsub(/[^a-z0-9\s_]/, '').gsub(' ', '_')
    else
      (self.class.name.underscore.gsub('/','_') + '__' + self.method_name.gsub(/^test[:_](\s?)/, '')).strip.downcase.squeeze(' ').gsub(/[^a-z0-9\s_]/, '').gsub(' ', '_')
    end
  end

  # This method will be overridden in Test::Unit with the alias_method_chain method below; it exists to make rspec work
  def setup_without_vcr
  end

  def setup_with_vcr
    # call this at the top of ActiveSupport::TestCase
    if record?
      FileUtils.rm_rf "#{VCR.configuration.cassette_library_dir}/#{cassette_name}.yml"
      VCR.insert_cassette(cassette_name, :record => :all)
      ::FakeWeb.allow_net_connect = true
    else
      VCR.insert_cassette(cassette_name, :record => :none, :match_requests_on => [:host, :path])
      ::FakeWeb.allow_net_connect = false
    end
    setup_without_vcr
  end

  # This method will be overridden in Test::Unit with the alias_method_chain method below; it exists to make rspec work
  def teardown_without_vcr
  end

  def teardown_with_vcr
    teardown_without_vcr
    VCR.eject_cassette
  end

  def self.included(base)
    base.class_eval do
      if base.respond_to?(:before)
        base.before do
          setup_with_vcr
        end
        base.after do
          teardown_with_vcr
        end
      else
        # We use alias method chain here because we need these setup methods to wrap the entire suit
        alias_method_chain :setup, :vcr
        alias_method_chain :teardown, :vcr
      end
    end
  end
end

