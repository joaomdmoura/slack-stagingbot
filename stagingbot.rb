# Instructions
# --------------------------------
#
# 1. Create a table
#
# ```
#   DATABASE = PG.connect(ENV['DATABASE_URL'])
#   DATABASE.exec "CREATE TABLE stagings(id INTEGER PRIMARY KEY, number INT, owner VARCHAR(100))"
# ```
#
# 2. Create existing stagings
#
# ```
# DATABASE.exec "INSERT INTO stagings VALUES(1,2, NULL)"
# DATABASE.exec "INSERT INTO stagings VALUES(2,3, NULL)"
# DATABASE.exec "INSERT INTO stagings VALUES(3,4, NULL)"
# DATABASE.exec "INSERT INTO stagings VALUES(4,5, NULL)"
# ```
# ==========================================
require 'slack-ruby-bot'
require 'pg'

class Database
  def self.staging(number)
    conn = PG.connect(ENV['DATABASE_URL'])
    staging = (conn.exec "SELECT * FROM stagings WHERE number =#{number.to_i} LIMIT 1").first
    conn.close
    return staging
  end

  def self.save_staging_usage(number, user)
    conn = PG.connect(ENV['DATABASE_URL'])
    staging = (conn.exec "UPDATE stagings SET owner='#{user}' WHERE number =#{number.to_i}").first
    conn.close
    return staging
  end
end

class StagingBot < SlackRubyBot::Bot
  command 'commands' do |client, data, match|
    client.say(text:
      'Available commands are:'\
      ' `use staging [2-5]`'\
      ' `release staging [2-5]`'\
      ' `servers`'\
    , channel: data.channel)
  end

  command /use staging [2-5]/ do |client, data, match|
    staging_number = /[2-5]/.match(match['command']).to_s
    user = Database.staging(staging_number)["owner"]

    if user && !user.empty?
      client.say(text: "I'm sorry <@#{data.user}>, but staging #{staging_number} is reserved to <@#{user}>.", channel: data.channel)
    else
      Database.save_staging_usage(staging_number, data.user)
      client.say(text: "Okay <@#{data.user}>, staging #{staging_number} is reserved to you.", channel: data.channel)
    end
  end

  command /release staging [2-5]/ do |client, data, match|
    staging_number = /[2-5]/.match(match['command']).to_s
    user = Database.staging(staging_number)["owner"]

    if user != data.user
      client.say(text: "I'm sorry <@#{data.user}>, you can't release staging #{staging_number} because <@#{user}> is the one that reserved it.", channel: data.channel)
    else
      Database.save_staging_usage(staging_number, nil)
      client.say(text: "Okay <@#{data.user}>, staging #{staging_number} is released.", channel: data.channel)
    end
  end

  command 'servers' do |client, data, match|
    staging_number = /[1-5]/.match(match['command']).to_s
    stagings = []
    (2..5).to_a.each do |s|
      stagings << Database.staging(s)["owner"]
    end

    client.say(text: "
- staging 2: #{(stagings[0] && stagings[0] != '') ? "<@#{stagings[0]}>" : "Available"}
- staging 3: #{(stagings[1] && stagings[1] != '') ? "<@#{stagings[1]}>" : "Available"}
- staging 4: #{(stagings[2] && stagings[2] != '') ? "<@#{stagings[2]}>" : "Available"}
- staging 5: #{(stagings[3] && stagings[3] != '') ? "<@#{stagings[3]}>" : "Available"}
    ", channel: data.channel)
  end
end

StagingBot.run