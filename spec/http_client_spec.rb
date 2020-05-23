# frozen_string_literal: true

require_relative File.join(%w[.. lib http_client])

ENV.delete('cache_dir')
ENV.delete('cert_file')
ENV.delete('cert_pass')

describe HttpClient do
  let(:cache_dir) { '/path/to/cache_dir' }
  let(:cert_file) { '/path/to/cert.p12' }
  let(:cert_pass) { 'cert-password' }
  let(:cert_data) { 'certificate encrypted content' }
  let(:config) do
    {
      cache_dir: cache_dir,
      cert_file: cert_file,
      cert_pass: cert_pass
    }
  end
  let(:empty_config) do
    {
      cache_dir: nil,
      cert_file: nil,
      cert_pass: nil
    }
  end
  let(:cert) { instance_double('OpenSSL::PKCS12') }

  before do
    allow(cert).to receive(:certificate).and_return('certificate content')
    allow(cert).to receive(:key).and_return('certificate key')
  end

  describe 'respond to' do
    it { is_expected.to respond_to :config }
    it { is_expected.to respond_to :cert }
    it { is_expected.to respond_to :request_options }
    it { is_expected.to respond_to :request_options= }
    it { is_expected.to respond_to :get }
  end

  describe '#initialize' do
    context 'with default config' do
      subject(:default_client) { described_class.new }

      it 'has an empty config' do
        expect(default_client.config).to eq(empty_config)
      end
      it 'has no certificate' do
        expect(default_client.cert).to be(nil)
      end
    end

    context 'with custom config' do
      subject(:custom_client) { described_class.new(config) }

      before do
        allow(File).to receive(:exist?).with(cert_file).and_return(true)
        allow(File).to receive(:read).with(cert_file, mode: 'rb') { cert_data }
        allow(OpenSSL::PKCS12).to receive(:new).with(cert_data, cert_pass) { cert }
      end

      it 'has a valid config' do
        expect(custom_client.config).to eq(config)
      end

      it 'has a valid certificate' do
        expect(custom_client.cert).to eq(cert)
      end
    end
  end

  describe '#request_options=' do
    let(:user_options) { { a: 1, b: 2 } }
    let(:user_ssl_options) { { a: 1, b: 2, ssl_client_cert: 3 } }

    context 'with default config' do
      subject(:default_client) { described_class.new }

      it 'does not modify user supplied options' do
        default_client.request_options = user_options
        expect(default_client.request_options).to eq(user_options)
      end
    end

    context 'with custom config' do
      subject(:custom_client) { described_class.new(config) }

      before do
        # set_cert
        allow(File).to receive(:exist?).with(cert_file).and_return(true)
        allow(File).to receive(:read).with(cert_file, mode: 'rb') { cert_data }
        allow(OpenSSL::PKCS12).to receive(:new).with(cert_data, cert_pass) { cert }
      end

      it 'extends user supplied options' do
        custom_client.request_options = user_options
        expect(custom_client.request_options).to include(user_options)
      end

      it 'overrides built-in cert options' do
        custom_client.request_options = user_ssl_options
        expect(custom_client.request_options).to include(user_ssl_options)
      end
    end
  end

  describe '#get' do
    subject(:default_get) { described_class.new(config).get('sample-url') }

    let(:cache_key) { 'md5-string' }
    let(:cache_file) { 'cache-file' }
    let(:endpoint_response) { 'data received from the endpoint' }
    let(:cache_content) { 'contents of the cache file' }
    let(:rest_resource) { instance_double('RestClient::Resource') }
    let(:rest_response) { instance_double('RestClient::Response') }

    before do
      # set_cert
      allow(File).to receive(:exist?).with(cert_file).and_return(true)
      allow(File).to receive(:read).with(cert_file, mode: 'rb') { cert_data }
      allow(OpenSSL::PKCS12).to receive(:new).with(cert_data, cert_pass) { cert }

      # cache_dir
      allow(File).to receive(:exist?).with(cache_dir).and_return(false)
      allow(File).to receive(:directory?).with(cache_dir).and_return(true)
      allow(FileUtils).to receive(:mkdir_p).with(cache_dir).and_return(true)

      # fetch
      allow(RestClient::Resource).to receive(:new).and_return(rest_resource)
      allow(rest_resource).to receive(:get).and_return(rest_response)
      allow(rest_response).to receive(:body).and_return(endpoint_response)

      # get
      allow(Digest::MD5).to receive(:hexdigest).and_return(cache_key)
      allow(File).to receive(:join).with(cache_dir, cache_key).and_return(cache_file)
    end

    context 'without cache file' do
      it 'fetches data from the endpoint' do
        allow(File).to receive(:exist?).with(cache_file).and_return(false)
        allow(File).to receive(:write)
          .with(cache_file, endpoint_response)
          .and_return(true)
        expect(default_get).to eq(endpoint_response)
      end
    end

    context 'with cache file' do
      it 'fetches data from the file' do
        allow(File).to receive(:exist?).with(cache_file).and_return(true)
        allow(File).to receive(:read).with(cache_file).and_return(cache_content)
        expect(default_get).to eq(cache_content)
      end
    end
  end
end
