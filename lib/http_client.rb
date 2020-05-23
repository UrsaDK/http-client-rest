# frozen_string_literal: true

# Fetches a response and permanently caches it

require 'digest/md5'
require 'fileutils'
require 'openssl'
require 'rest-client'

class HttpClient
  attr_reader :config, :cert, :request_options

  CONFIG = {
    cache_dir: ENV['cache_dir'],
    cert_file: ENV['cert_file'],
    cert_pass: ENV['cert_pass']
  }.freeze

  def initialize(config = {})
    @config = CONFIG.merge(config)
    @cert = set_cert(config[:cert_file], config[:cert_pass]) if config[:cert_file]
  end

  def request_options=(options)
    @request_options = cert.nil? ? options : cert_options.merge(options)
  end

  def get(url, cache_key = nil)
    cache_key ||= Digest::MD5.hexdigest url
    cache_file = File.join(cache_dir, cache_key)
    if File.exist?(cache_file)
      File.read(cache_file)
    else
      fetch(url).body.tap do |response|
        File.write(cache_file, response)
      end
    end
  end

  private

  def cert_options
    {
      ssl_client_cert: cert.certificate,
      ssl_client_key: cert.key
    }
  end

  def set_cert(file, password)
    raise 'Certificat file does not exist' unless File.exist? file
    cert_data = File.read file, mode: 'rb'
    OpenSSL::PKCS12.new cert_data, password
  end

  def cache_dir
    @cache_dir ||= config[:cache_dir].tap do |dir|
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      raise "Cache does not point to a directory: #{dir}" unless File.directory?(dir)
    end
  end

  def fetch(url)
    client = RestClient::Resource.new url, request_options
    client.get
  rescue RestClient::ExceptionWithResponse => e
    raise "Error fetching #{url}: #{e.response}"
  rescue StandardError => e
    raise "Failed to fetch #{url} -- #{e.message}"
  end
end
