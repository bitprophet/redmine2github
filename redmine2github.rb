require 'rubygems'
require 'json'

REPO = ENV['REPO'] || "bitprophet/issuetest"

ENV['RESTCLIENT_LOG'] = 'stdout'
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


repo = GitHub.new "repos/#{REPO}"
github = GitHub.new
skipped_ids = []

Issue.find(:all, :order => "id ASC").each do |issue|
  puts ">>> [#{issue.id}] #{issue.subject}"
  #begin
  #  gh = github.issue(issue.id)
  #  puts "!! Issue ##{issue.id} already exists on GitHub: #{gh['title']}"
  #  puts "!! Skipping."
  #  skipped_ids << issue.id
  #  next
  #rescue RestClient::ResourceNotFound
    break if issue.id > 5
    # Create new issue based on mapping
    params = {
      :title => issue.subject,
      :body => issue.description,
      :assignee => "bitprophet", # Always assigned to me
    }
    #   Submitter note in desc
    unless issue.author.login == "jforcier"
      params[:body] << "\n\nOriginally submitted by **#{issue.author.login}**"
    end
    #   Create date in desc
    # If issue was closed, close it on GH
    # Set labels for "dupe", "wontfix" etc
    # Set labels for quick, wart, others?
    # For each attachment:
    #   If not text in nature, warn & skip
    #   Create gist
    #   Add note at bottom of desc w/ link
    # For each related issue:
    #   Add note+link at bottom of desc
    # For each journal/comment, sorting by created_on:
    #   Add to GH issue
    #   Include original username, submit date in body field
    # Assign to appropriate milestone:
    #   If closed, assign to real closed milestone
    #   If open, label as 1.x or 2.x - no milestone
    puts "Would generate following POST params hash:"
    pp params
    puts ""
    #repo['/issues'].post(params.to_json, :content_type => 'text/json')
  #end
end

puts "Skipped #{skipped_ids.size} issue(s) numbered #{skipped_ids.join(", ")}."
