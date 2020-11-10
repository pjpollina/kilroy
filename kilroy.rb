$LOAD_PATH << File.expand_path(File.dirname(__FILE__)).chomp('/.')

require 'dotenv/load'
require 'discordrb'
require 'lib/mysql'
require 'lib/backup'
require 'lib/status'

REG_RUN  = /\A(?:1)?[0-9]\.[0-9], [0-9]{1,2}m\z/
REG_HILL = /\A[1-9]\.[0-9], [0-9]{1,2}m, [1-9]\.[0-9]%\z/

INSERT_RUN  = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes) VALUES(CURDATE(), ?, ?)'
INSERT_HILL = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES(CURDATE(), ?, ?, ?)'

mysql = MySQL.new('kilroy', ENV['discord_bot_token'], 'fitness', ENV['sql_host'] || 'localhost')

kilroy = Discordrb::Bot.new(
  token:      ENV['discord_bot_token'],
  client_id:  ENV['discord_bot_id']
)

kilroy.message(in: '#cardio') do |event|
  case event.content
  when REG_RUN
    mph, minutes = event.content.split(', ')
    mysql.connect do |client|
      stmt = client.prepare(INSERT_RUN)
      stmt.execute(mph.to_f, minutes.chomp(?m).to_i)
      Backup.write(mph, minutes)
      stmt.close
    end
    puts "Run:\t#{event.content}"
  when REG_HILL
    mph, minutes, incline = event.content.split(', ')
    mysql.connect do |client|
      stmt = client.prepare(INSERT_HILL)
      stmt.execute(mph.to_f, minutes.chomp(?m).to_i, incline.chomp('%').to_f)
      Backup.write(mph, minutes, incline)
      stmt.close
    end
    puts "Hill:\t#{event.content}"
  else
    event.respond("Unrecognized cardio format")
  end
end

kilroy.message(in: '#weigh-ins') do |event|
  weight = event.content.chomp('lbs').to_f
  if(weight != 0.0)
    mysql.connect do |client|
      stmt = client.prepare('INSERT INTO weigh_ins(wi_date, wi_lbs) VALUES(CURDATE(), ?)')
      stmt.execute(weight)
      stmt.close
    end
    puts "Weigh-in:\t#{event.content}"
  else
    event.respond("Improper weight format")
  end
end

kilroy.message(in: '#status') do |event|
  unless(event.content.match?(/\A~totals (.*)/) || event.content.match?(/\A~hills (.*)/))
    event.respond "Unknown command #{event.content}"
    next
  end

  command = event.content.split(' ')
  if(command.count > 1 && ['month', 'semester', 'year'].include?(command[1]))
    args = Status.getter_args(command)
    message = ""
    mysql.connect do |client|
      stmt = client.prepare(Status.getter_statement(command))
      message << Status.response(stmt.execute(*args, symbolize_keys: true), command)
      stmt.close
    end
    event.respond(message)
  else
    event.respond("Missing or unrecognized qualifier for command \"#{command[0][1..-1]}\"")
  end
end

kilroy.run