# frozen_string_literal: true

require_relative "adobe_doc_api/version"
require "adobe_doc_api/configuration"

module AdobeDocApi
  autoload :Client, "adobe_doc_api/client"
  autoload :Error, "adobe_doc_api/error"

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

end
