require 'github'

POST_OK = true

repo = GitHub.new "repos/#{REPO}"
github = GitHub.new
skipped_ids = []

#issue_ids = %w(282 358 114 3 10 7)
issue_ids = %w(49)
issues = issue_ids.map {|x| Issue.find(x)}


def submitter_link(github, author)
  map = {
    'jforcier' => 'bitprophet'
  }
  submitter = map.fetch author.login, author.login
  begin
    gh_user = JSON.parse github["users/#{submitter}"].get
    "**#{gh_user['name']}** ([#{submitter}](#{gh_user['html_url']}))"
  rescue RestClient::ResourceNotFound
    "**#{author.name}** (#{submitter})"
  end
end

def submit_date(github, object)
  " on #{object.created_on.strftime("**%F** at **%I:%M%P %Z**")}"
end

def submit_line(github, author, object)
  link = submitter_link(github, author)
  submitter_text = link ? " by #{link}" : ""
  "\n\n----\n\nOriginally submitted#{submitter_text}#{submit_date(github, object)}"
end


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
    params[:body] << submit_line(github, issue.author, issue)
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
    params[:body] << "\n\n### Relations\n\n" unless issue.relations.empty?
    # Have to do this in two parts so we know which side of the relation object
    # to nab.
    %w(to from).each do |which|
      issue.send("relations_#{which}".to_sym).each do |relation|
        # Add note+link at bottom of desc
        i = relation.send("issue_#{which=='from' ? 'to' : 'from'}".to_sym)
        params[:body] << "* ##{i.id}: #{i.subject}\n"
      end
    end
    # Assign to appropriate milestone:
    #   If closed, assign to real closed milestone
    #   If open, label as 1.x or 2.x - no milestone
    # If issue was closed, close it on GH
    puts "Would generate following POST params hash:"
    pp params
    puts ""
    puts "Human readable body text:"
    puts params[:body]

    # For each journal/comment, sorting by created_on:
    comment_params = []
    issue.journals.sort_by {|x| x.created_on}.each do |journal|
      next unless journal.notes
      body = journal.notes
      # Include original username, submit date in body field
      body << submit_line(github, journal.user, journal)
      # Add to GH issue
      comment_params << {:body => body}
    end
    puts ""
    puts "Would generate following comment params hashes:"
    pp comment_params

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
      response = repo['/issues'].post(params.to_json, :content_type => 'text/json')
      # Post comments!
      comment_params.each do |comment|
        repo["/issues/#{JSON.parse(response)['number']}/comments"].post(
          comment.to_json, :content_type => 'text/json'
        )
      end
    rescue => e
      pp e
      pp JSON.parse(e.response)
      raise
    end if POST_OK

  #end
end

puts "Skipped #{skipped_ids.size} issue(s) numbered #{skipped_ids.join(", ")}."
