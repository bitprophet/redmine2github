require 'httparty'

class GitHub
  include HTTParty
  base_uri "https://api.github.com"
  basic_auth ENV['GITHUB_USERNAME'], ENV['GITHUB_PASSWORD']
end
