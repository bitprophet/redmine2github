require 'rubygems'
require 'rest_client'
require 'json'

REPO = ENV['REPO'] || "bitprophet/redmine2github"


class GitHub
  def initialize
    @api = RestClient::Resource.new(
      "https://api.github.com/repos/#{REPO}",
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


github = GitHub.new
skipped_ids = []

Issue.find(:all, :order => "id ASC").each do |issue|
  puts ">>> [#{issue.id}] #{issue.subject}"
  begin
    gh = github.issue(issue.id)
    puts gh.
    puts "!! Issue ##{issue.id} already exists on GitHub: #{gh['title']}"
    puts "!! Skipping."
    skipped_ids << issue.id
    next
  rescue RestClient::ResourceNotFound
    puts "not on gh"
    exit if issue.id > 5
  end
end
