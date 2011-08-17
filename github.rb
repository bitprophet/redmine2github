require 'rubygems'
require 'json'

POST_OK = true
#POST_OK = false
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


class ItemCache
  def initialize(api, urlpart, key)
    @api = api
    @urlpart = urlpart
    @key = key
    @items = {}
  end

  def fetch(params={})
    items = {}
    JSON.parse(@api[@urlpart].get(:params => params)).each do |item|
      items[item[@key]] = item
    end
    items
  end

  def list
    @items = fetch if @items.empty?
    @items
  end

  def create(value)
    @items[value] = if POST_OK
      JSON.parse(@api[@urlpart].post(
        {@key => value}.to_json,
        :content_type => 'text/json'
      ))
    else
      {@key => value, :number => 1}
    end
  end

  def get(value)
    list.fetch(value) do
      create(value)
    end
  end
end


class MilestoneCache < ItemCache
  def list
    if @items.empty?
      @items.merge! fetch(:state => "open")
      @items.merge! fetch(:state => "closed")
    end
    @items
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
    begin
    @users[username] ||= begin
      JSON.parse @api["users/#{username}"].get
    rescue RestClient::ResourceNotFound
      NoSuchUser.new
    end
    rescue => e
      pp e
      pp JSON.parse(e.response)
      raise
    end
  end
end


REPO = GithubAPI.new "repos/#{REPO_PATH}"
GITHUB = GithubAPI.new
MILESTONES = MilestoneCache.new REPO, '/milestones', 'title'
USERS = UserCache.new GITHUB
LABELS = ItemCache.new REPO, '/labels', 'name'
