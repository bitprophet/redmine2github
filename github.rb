require 'rubygems'
require 'json'

REPO_PATH = ENV['REPO'] || "bitprophet/issuetest"

ENV['RESTCLIENT_LOG'] = 'stdout'
require 'rest_client'


class GithubAPI
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


class MilestoneCache
  def initialize(api)
    @api = api
    @milestones = {}
  end

  def list_milestones
    JSON.parse(@api['/milestones'].get).each do |milestone|
      @milestones[milestone['title']] = milestone
    end if @milestones.empty?
    @milestones
  end

  def get_milestone(name)
    list_milestones.fetch(name) do
      JSON.parse(@api['/milestones'].post(
        {'title' => name}.to_json,
        :content_type => 'text/json'
      ))
    end
  end
end


REPO = GithubAPI.new "repos/#{REPO_PATH}"
GITHUB = GithubAPI.new
MILESTONES = MilestoneCache.new REPO
