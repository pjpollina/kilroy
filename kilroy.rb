require 'discordrb'
require 'mysql2'

REG_RUN  = /\A[1-9]\.[0-9], [0-9]{1,2}m\z/
REG_HILL = /\A[1-9]\.[0-9], [0-9]{1,2}m, [1-9]\.[0-9]%\z/

dbclient = Mysql2::Client.new(
  username: 'kilroy',
  password: ENV['discord_bot_token'],
  database: 'fitness'
)
insert_run  = dbclient.prepare('INSERT INTO cardio(cd_date, cd_mph, cd_minutes) VALUES(CURDATE(), ?, ?)')
insert_hill = dbclient.prepare('INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES(CURDATE(), ?, ?, ?)')

kilroy = Discordrb::Bot.new(
  token:      ENV['discord_bot_token'],
  client_id:  ENV['discord_bot_id']
)

kilroy.message(in: '#cardio') do |event|
  case event.content
  when REG_RUN
    mph, minutes = event.content.split(', ')
    insert_run.execute(mph.to_f, minutes.chomp(?m).to_i)
    puts "Run:\t#{event.content}"
  when REG_HILL
    mph, minutes, incline = event.content.split(', ')
    insert_hill.execute(mph.to_f, minutes.chomp(?m).to_i, incline.chomp('%').to_f)
    puts "Hill:\t#{event.content}"
  else
    event.respond("Unrecognized cardio format")
  end
end

kilroy.run