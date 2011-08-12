require 'rubygems'
require 'json'

REPO = ENV['REPO'] || "bitprophet/issuetest"

#ENV['RESTCLIENT_LOG'] = 'stdout'
require 'rest_client'


class GitHub
  def initialize(section="")
    @api = RestClient::Resource.new(
      "https://api.github.com/#{section}",
      ENV['GITHUB_USERNAME'],
      ENV['GITHUB_PASSWORD']
    )
  end

  def issues
    @api["/issues"].get
  end

  def issue(id)
    @api["/issues/#{id}"].get
  end

  def method_missing(sym, *args, &block)
    @api.send(sym, *args, &block)
  end
end
