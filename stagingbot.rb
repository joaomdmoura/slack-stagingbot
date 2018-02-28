require 'yaml/store'
require 'slack-ruby-bot'

class Database
  DATABASE = YAML::Store.new('stagingbot_db.yml')

  def self.staging(number)
    database = YAML.load_file('stagingbot_db.yml')
    database["staging_usage"][number.to_i]
  end

  def self.save_staging_usage(number, user)
    DATABASE.transaction do
      DATABASE["staging_usage"] ||= []
      DATABASE["staging_usage"][number.to_i] = user
    end
  end
end

class StagingBot < SlackRubyBot::Bot
  command /use staging [1-4]/ do |client, data, match|
    begin
      staging_number = /[1-4]/.match(match['command']).to_s
      user = Database.staging(staging_number)

      if user
        client.say(text: "I'm sorry <@#{data.user}>, but staging #{staging_number} is reserved to <@#{user}>.", channel: data.channel)
      else
        Database.save_staging_usage(staging_number, data.user)
        client.say(text: "Okay <@#{data.user}>, staging #{staging_number} is reserved to you.", channel: data.channel)
      end
    end
  end

  command /release staging [1-4]/ do |client, data, match|
    begin
      staging_number = /[1-4]/.match(match['command']).to_s
      user = Database.staging(staging_number)

      if user != data.user
        client.say(text: "I'm sorry <@#{data.user}>, you can't release staging #{staging_number} because <@#{user}> is the one that reserved it.", channel: data.channel)
      else
        Database.save_staging_usage(staging_number, nil)
        client.say(text: "Okay <@#{data.user}>, staging #{staging_number} is released.", channel: data.channel)
      end
    end
  end

  command 'servers' do |client, data, match|
    staging_number = /[1-4]/.match(match['command']).to_s
    stagings = []
    (1..4).to_a.each do |s|
      stagings << Database.staging(s)
    end

    client.say(text: "
- staging 1: #{(stagings[0]) ? "<@#{stagings[0]}>" : "Available"}
- staging 2: #{(stagings[1]) ? "<@#{stagings[1]}>" : "Available"}
- staging 3: #{(stagings[2]) ? "<@#{stagings[2]}>" : "Available"}
- staging 4: #{(stagings[3]) ? "<@#{stagings[3]}>" : "Available"}
    ", channel: data.channel)
  end
end

StagingBot.run