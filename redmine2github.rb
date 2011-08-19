require 'github'


def submit_link(github, author)
  map = {
    'jforcier' => 'bitprophet'
  }
  submitter = map.fetch author.login, author.login
  gh_user = USERS.get submitter
  if gh_user.class == NoSuchUser
    "**#{author.name}** (#{submitter})"
  else
    "**#{gh_user['name']}** ([#{submitter}](#{gh_user['html_url']}))"
  end
end

def date(object, attr=:created_on)
  object.send(attr).strftime(" on **%F** at **%I:%M%P %Z**")
end

# Store comments, closed status as we go, post 'em at the end
comments = {}
closed = []

1.upto(Issue.last.id) do |redmine_id|
  begin
    issue = Issue.find redmine_id
  rescue ActiveRecord::RecordNotFound
    puts "!!! No issue with ID #{redmine_id} found; creating dummy."
    params = {
      :title => "Dummy issue, ignore",
      :body => "This issue intentionally left blank."
    }
    response = REPO['/issues'].post(params.to_json, :content_type => 'text/json')
    closed << redmine_id
    next
  end
  puts ">>> [#{issue.id}] #{issue.subject}"
  # Create new issue based on mapping
  params = {
    :title => issue.subject,
    :body => "### Description\n\n" + issue.description,
    :assignee => "bitprophet", # Always assigned to me
    :labels => []
  }

  #   Create date in desc #   Submitter note in desc
  params[:body] << "\n\n----\n\nOriginally submitted by #{submit_link(GITHUB, issue.author) + date(issue)}"

  # Some random-access-friendly priorities
  priority = issue.priority.name
  params[:labels] << priority if %w(Quick Wart).include?(priority)
  # Tracker name (bug, feature, support)
  params[:labels] << issue.tracker.name
  # Category (with some transformations)
  if issue.category
    category = issue.category.name
    params[:labels] << {
      "CLI" => "UI"
    }.fetch(category, category)
  end

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
    response = GITHUB["gists"].post({
      :public => false,
      :description => a.description,
      :files => {
        a.filename => {:content => File.new(a.diskfile, "rb").read}
      }
    }.to_json)
    gisted[a.filename] = JSON.parse(response)['html_url']
  end
  # Add note at bottom of desc w/ link
  unless gisted.empty?
    params[:body] << "\n\n### Attachments\n\n"
    params[:body] << gisted.map {|name, url| "* [#{name}](#{url})"}.join("\n")
  end

  # For each related issue:
  params[:body] << "\n\n### Relations\n\n" unless issue.relations.empty?
  # Have to do this in two parts so we know which side of the relation object
  # to nab.
  %w(to from).each do |which|
    issue.send("relations_#{which}".to_sym).each do |relation|
      # Add note+link at bottom of desc
      i = relation.send("issue_#{which=='from' ? 'to' : 'from'}".to_sym)
      rel = GLoc::l(relation.label_for(i)).capitalize
      params[:body] << "* #{rel} ##{i.id}: #{i.subject}\n"
    end
  end

  # Assign to appropriate milestone and handle closed status
  is_closed = false
  status = issue.status
  if status.is_closed
    # If closed, assign to real closed milestone
    # TODO: close milestone
    if issue.fixed_version
      milestone = MILESTONES.get(issue.fixed_version.name)
      params[:milestone] = milestone['number']
    end
    # If issue was closed, close it on GH
    is_closed = true
    # And add the "why" to the body
    params[:body] << "\n\n----\n\nClosed as *#{status.name}*#{date(issue, :updated_on)}"
  else
    # If open, label as 0.9.x, 1.x or 2.x - no milestone
    %w(0.9 1 2).each do |which|
      if issue.fixed_version.name =~ /^#{which}\./
        params[:labels] << "#{which}.x"
      end
    end if issue.fixed_version
  end

  # For each journal/comment, sorting by created_on:
  comment_params = []
  issue.journals.sort_by {|x| x.created_on}.each do |journal|
    next if journal.notes.nil? || journal.notes.empty?
    body = journal.notes
    # Include original username, submit date in body field
    body =  "#{submit_link(GITHUB, journal.user)} posted:\n\n----\n\n#{body}\n\n----\n\n#{date(journal)}"
    # Add to GH issue
    comment_params << {:body => body}
  end

  begin
    # Ensure labels exist
    params[:labels].each do |label|
      # Just using for its side effect right now
      LABELS.get(label)
    end
    # Post it!
    response = REPO['/issues'].post(params.to_json, :content_type => 'text/json')
    gh_issue = JSON.parse(response)
    gh_id = gh_issue['number']
    # Sanity check
    if gh_id != redmine_id
      puts "!!! Posted Redmine issue ##{redmine_id} but got back Github issue ##{gh_id}"
      exit 1
    end
    # Store comments!
    comments[gh_id] = comment_params
    # Store closed status!
    closed << gh_id if is_closed
  rescue => e
    pp e
    pp JSON.parse(e.response)
    raise
  end if POST_OK
end

# Post comments!
print "\nCommenting"
comments.each do |number, comment_params|
  comment_params.each do |comment|
    REPO["/issues/#{number}/comments"].post(
      comment.to_json, :content_type => 'text/json'
    )
  end
  print "."
end
print "\n"

# Close!
print "\nClosing"
closed.each do |number|
  REPO["/issues/#{number}"].post(
    {:state => "closed"}.to_json,
    :content_type => "text/json"
  )
  print "."
end
print "\n"
