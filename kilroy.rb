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
insert_weigh_in = dbclient.prepare('INSERT INTO weigh_ins(wi_date, wi_lbs) VALUES(CURDATE(), ?)')
select_month_totals = dbclient.prepare('SELECT cd_mph, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE MONTH(cd_date)=? GROUP BY cd_mph')

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

kilroy.message(in: '#weigh-ins') do |event|
  weight = event.content.chomp('lbs').to_f
  if(weight != 0.0)
    insert_weigh_in.execute(weight)
  else
    event.respond("Improper weight format")
  end
end

kilroy.message(in: '#status') do |event|
  case event.content
  when '~totals month'
    response = "Month totals:"
    select_month_totals.execute(Time.now.month, symbolize_keys: true).each do |total|
      response << "#{total[:cd_mph]}\t#{total[:minutes]}\t#{total[:distance]}"
    end
    puts response
    event.respond(response)
  end
end

kilroy.run