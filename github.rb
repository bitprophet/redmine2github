require 'rubygems'
require 'json'

REPO = ENV['REPO'] || "bitprophet/issuetest"

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
  end

  def list_milestones
    JSON.parse @api['/milestones'].get
  end

  def get_milestone(name)
    matches = list_milestones.select {|x| x['title'] == name}
    pp matches
    if matches.size > 1
      puts "!!! Tried to get milestone '#{name}' and got back >1 match!"
      exit 1
    elsif matches.size == 1
      matches[0]
    else
      JSON.parse @api['/milestones'].post(
        {'title' => name}.to_json,
        :content_type => 'text/json'
      )
    end
  end
end


REPO = GithubAPI.new "repos/#{REPO}"
GITHUB = GithubAPI.new
MILESTONES = MilestoneCache.new REPO
