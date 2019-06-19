require 'discordrb'
require './mysql'

REG_RUN  = /\A[1-9]\.[0-9], [0-9]{1,2}m\z/
REG_HILL = /\A[1-9]\.[0-9], [0-9]{1,2}m, [1-9]\.[0-9]%\z/

mysql = MySQL.new('kilroy', ENV['discord_bot_token'], 'fitness')

kilroy = Discordrb::Bot.new(
  token:      ENV['discord_bot_token'],
  client_id:  ENV['discord_bot_id']
)

kilroy.message(in: '#cardio') do |event|
  case event.content
  when REG_RUN
    mph, minutes = event.content.split(', ')
    mysql.connect do |client|
      stmt = client.prepare('INSERT INTO cardio(cd_date, cd_mph, cd_minutes) VALUES(CURDATE(), ?, ?)')
      stmt.execute(mph.to_f, minutes.chomp(?m).to_i)
      File.open(File.expand_path(Time.now.strftime("../cardio-log/%m%B.sql").downcase), 'a') do |file|
        file.puts "INSERT INTO cardio(cd_date, cd_mph, cd_minutes)             VALUES('#{Time.now.strftime("%F")}', #{mph}, #{minutes.chomp(?m)});"
      end
      stmt.close
    end
    puts "Run:\t#{event.content}"
  when REG_HILL
    mph, minutes, incline = event.content.split(', ')
    mysql.connect do |client|
      stmt = client.prepare('INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES(CURDATE(), ?, ?, ?)')
      stmt.execute(mph.to_f, minutes.chomp(?m).to_i, incline.chomp('%').to_f)
      File.open(File.expand_path(Time.now.strftime("../cardio-log/%m%B.sql").downcase), 'a') do |file|
        file.puts "INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES('#{Time.now.strftime("%F")}', #{mph}, #{minutes.chomp(?m)}, #{incline.chomp('%')});"
      end
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
  else
    event.respond("Improper weight format")
  end
end

kilroy.message(in: '#status') do |event|
  case event.content
  when '~totals month'
    message = "Month totals:\r\n"
    mysql.connect do |client|
      stmt = client.prepare('SELECT cd_mph, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE MONTH(cd_date)=? GROUP BY cd_mph')
      stmt.execute(Time.now.month, symbolize_keys: true).each do |total|
        message << "#{total[:cd_mph]}\t#{total[:minutes].to_i}\t#{total[:distance].round(3)}\r\n"
      end
      event.respond(message)
      stmt.close
    end
  end
end

kilroy.run