$LOAD_PATH << File.expand_path(File.dirname(__FILE__)).chomp('/.')

require 'dotenv/load'
require 'discordrb'
require 'lib/mysql'
require 'lib/backup'

REG_RUN  = /\A(?:1)?[0-9]\.[0-9], [0-9]{1,2}m\z/
REG_HILL = /\A[1-9]\.[0-9], [0-9]{1,2}m, [1-9]\.[0-9]%\z/

INSERT_RUN  = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes) VALUES(CURDATE(), ?, ?)'
INSERT_HILL = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES(CURDATE(), ?, ?, ?)'

def month_args(offset=0)
  month, year = Time.now.month, Time.now.year
  if(offset != 0)
    month -= offset
    until(month > 0)
      month += 12
      year -= 1
    end
  end
  return month, year
end

def semester_args(offset=0)
  sem = (Time.now.month < 7) ? 1 : 7
  year = Time.now.year
  if(offset != 0)
    sem -= (offset * 6)
    until(sem > 0)
      sem += 12
      year -= 1
    end
  end
  return sem, sem + 5, year
end

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
  statements = {
    "~totals" => [
      'SELECT cd_mph, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE ',
      'mph'
    ],
    "~hills" => [
      'SELECT cd_incline, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE cd_mph=4.0 AND ',
      'incline'
    ]
  }
  span_constraints = {
    'month'    => 'MONTH(cd_date)=? AND YEAR(cd_date)=?',
    'semester' => 'MONTH(cd_date) BETWEEN ? AND ? AND YEAR(cd_date)=?',
    'year'     => 'YEAR(cd_date)=?'
  }

  unless(event.content.match?(/\A~totals (.*)/) || event.content.match?(/\A~hills (.*)/))
    event.respond "Unknown command #{event.content}"
    next
  end

  command = event.content.split(' ')
  statement = "#{statements[command[0]][0]} #{span_constraints[command[1]]} GROUP BY cd_#{statements[command[0]][1]}"
  if(command.count > 1 && span_constraints.keys.include?(command[1]))
    args = []
    case command[1]
      when 'month'    then args = month_args
      when 'semester' then args = semester_args
      when 'year'     then args = [Time.now.year]
    end
    message = "```#{command[1].capitalize} #{command[0][1..-1]}:\r\n"
    mysql.connect do |client|
      all = Hash.new(0)
      stmt = client.prepare(statement)
      stmt.execute(*args, symbolize_keys: true).each do |total|
        if(command[0] == '~totals')
          message << "#{total[:cd_mph].to_s.ljust(4)}\t#{total[:minutes].to_i.to_s.rjust(5)}\t#{("%.3f" % total[:distance].round(3)).rjust(7)}\r\n"
          total.keys.each {|key| all[key] += total[key]}
        else
          message << "#{total[:cd_incline].to_s.rjust(4)}\t#{total[:minutes].to_i.to_s.rjust(4)}\t#{("%.3f" % total[:distance].round(3)).rjust(7)}\r\n"
        end
      end
      message << "ALL \t#{all[:minutes].to_i.to_s.rjust(5)}\t#{("%.3f" % all[:distance].round(3)).rjust(7)}\r\n" unless all.empty?
    end
    event.respond(message + '```')
  else
    event.respond("Missing or unrecognized qualifier for command \"#{command[0][1..-1]}\"")
  end
end

kilroy.run