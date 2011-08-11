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

issue_ids = %w(282 358 114 3 10)
issues = issue_ids.map {|x| Issue.find(x)}

#Issue.find(:all, :order => "id ASC").each do |issue|
issues.each do |issue|
  puts ">>> [#{issue.id}] #{issue.subject}"
  #begin
  #  gh = github.issue(issue.id)
  #  puts "!! Issue ##{issue.id} already exists on GitHub: #{gh['title']}"
  #  puts "!! Skipping."
  #  skipped_ids << issue.id
  #  next
  #rescue RestClient::ResourceNotFound
    # Create new issue based on mapping
    params = {
      :title => issue.subject,
      :body => "### Description\n\n" + issue.description,
      :assignee => "bitprophet", # Always assigned to me
      :labels => []
    }
    #   Create date in desc #   Submitter note in desc
    submitter_text = unless issue.author.login == "jforcier"
      submitter = issue.author.login
      submitter_link = begin
        gh_user = JSON.parse github["users/#{submitter}"].get
        "**#{gh_user['name']}** ([#{submitter}](#{gh_user['html_url']}))"
      rescue RestClient::ResourceNotFound
        "**#{issue.author.name}** (#{submitter})"
      end
      " by #{submitter_link}"
    else
      ""
    end
    create_date = " on #{issue.created_on.strftime("**%F** at **%I:%M%P %Z**")}"
    params[:body] << "\n\n----\n\nOriginally submitted#{submitter_text}#{create_date}"
    # Set labels for quick, wart, others?
    priority = issue.priority.name
    params[:labels] << priority if %w(Quick Wart).include?(priority)
    # Bug, feature, support
    params[:labels] << issue.tracker.name
    # For each attachment:
    gisted = {}
    issue.attachments.each do |a|
      puts "\t #{a.filename} (#{a.content_type}) [#{a.filesize}]"
      # If not text in nature, warn & skip
      # All attachment filetypes are some form of text except this one
      if a.content_type == "application/octet-stream"
        puts "\t\t Non-text filetype, manually port this one"
        next
      end
      # Create gist
      response = github["gists"].post({
        :public => false,
        :description => a.description,
        :files => {
          a.filename => {:content => File.new(a.diskfile, "rb").read}
        }
      }.to_json)
      gisted[a.filename] = JSON.parse(response)['html_url']
    end
    # Add note at bottom of desc w/ link
    if gisted
      params[:body] << "\n\n### Attachments\n\n"
      params[:body] << gisted.map {|name, url| "* [#{name}](#{url})"}.join("\n")
    end
    # For each related issue:
    #   Add note+link at bottom of desc
    # For each journal/comment, sorting by created_on:
    #   Add to GH issue
    #   Include original username, submit date in body field
    # Assign to appropriate milestone:
    #   If closed, assign to real closed milestone
    #   If open, label as 1.x or 2.x - no milestone
    # If issue was closed, close it on GH
    #puts "Would generate following POST params hash:"
    #pp params
    #puts ""
    #puts "Human readable body text:"
    #puts params[:body]
    begin
    # Ensure labels exist
    params[:labels].each do |label|
      begin
        repo["/labels/#{label}"].get
      rescue RestClient::ResourceNotFound
        puts ">> Creating new label '#{label}'"
        repo["/labels"].post({:name => label}.to_json)
      end
    end
    # Post it!
    #repo['/issues'].post(params.to_json, :content_type => 'text/json')
    rescue => e
      pp JSON.parse(e.response)
      raise
    end
  #end
end

puts "Skipped #{skipped_ids.size} issue(s) numbered #{skipped_ids.join(", ")}."
