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

  def list
    JSON.parse(@api['/milestones'].get).each do |milestone|
      @milestones[milestone['title']] = milestone
    end if @milestones.empty?
    @milestones
  end

  def create(name, closed=false)
    JSON.parse(@api['/milestones'].post(
      {'title' => name}.to_json,
      :content_type => 'text/json'
    ))
  end

  def get(name, closed=false)
    list.fetch(name) do
      create(name, closed)
    end
  end
end

class NoSuchUser
end

class UserCache
  def initialize(api)
    @api = api
    @users = {}
  end

  def get(username)
    @users[username] ||= begin
      JSON.parse @api["users/#{username}"].get
    rescue RestClient::ResourceNotFound
      NoSuchUser.new
    end
  end
end


REPO = GithubAPI.new "repos/#{REPO_PATH}"
GITHUB = GithubAPI.new
MILESTONES = MilestoneCache.new REPO
USERS = UserCache.new GITHUB
