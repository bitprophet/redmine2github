require 'rubygems'
require 'json'

POST_OK = true
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

  def list
    JSON.parse(@api[@urlpart].get).each do |item|
      @items[item[@key]] = item
    end if @items.empty?
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
MILESTONES = ItemCache.new REPO, '/milestones', 'title'
USERS = UserCache.new GITHUB
LABELS = ItemCache.new REPO, '/labels', 'name'
