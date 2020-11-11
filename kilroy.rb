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
    mysql.execute(INSERT_RUN, [mph.to_f, minutes.chomp(?m).to_i])
    Backup.write(mph, minutes)
    puts "Run:\t#{event.content}"
  when REG_HILL
    mph, minutes, incline = event.content.split(', ')
    mysql.execute(INSERT_HILL, [mph.to_f, minutes.chomp(?m).to_i, incline.chomp('%').to_f])
    Backup.write(mph, minutes, incline)
    puts "Hill:\t#{event.content}"
  else
    event.respond("Unrecognized cardio format")
  end
end

kilroy.message(in: '#status') do |event|
  next unless Status.valid_command?(event, "Unknown command #{event.content}")
  command = event.content.split(' ')
  if(command.count > 1 && ['month', 'semester', 'year'].include?(command[1]))
    mysql.execute(Status.getter_statement(command), Status.getter_args(command)) do |results|
      event.respond(Status.response(results, command))
    end
  else
    event.respond("Missing or unrecognized qualifier for command \"#{command[0][1..-1]}\"")
  end
end

kilroy.run