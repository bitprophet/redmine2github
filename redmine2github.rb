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
    puts "!! Issue ##{issue.id} already exists on GitHub: #{gh['title']}"
    puts "!! Skipping."
    skipped_ids << issue.id
    next
  rescue RestClient::ResourceNotFound
    # Create new issue based on mapping, and:
    #   Submitter note in desc
    #   Assigned to me
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
    break if issue.id > 5
  end
end

puts "Skipped #{skipped_ids.size} issue(s) numbered #{skipped_ids.join(", ")}."
