# Functions related to messages in the status channel

module Status
  extend self

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
    month = Time.now.month - ((Time.now.month < 7) ? 1 : 7)
    sem, year = month_args(month + (offset * 6))
    return sem, sem + 5, year
  end

  def round_off(speed, time)
    roundtime = 30 - (time % 30)
    rounddistance = (speed / 60) * (time + roundtime)
    until(rounddistance % 1 == 0)
      roundtime += 30
      rounddistance = (speed / 60) * (time + roundtime)
    end
    return roundtime, rounddistance
  end

  def row(total, main_key)
    row = "#{total[main_key].to_s.ljust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(5)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\r\n"
    return row
  end

  def getter_statement(command)
    stmt, grouper = "SELECT cd_mph, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE ", "mph"
    if(command[0].eql?("~hills"))
      stmt = stmt.gsub("mph", "incline") + "cd_mph=4.0 AND "
      grouper = "incline"
    end
    case command[1]
      when 'month'    then stmt += 'MONTH(cd_date)=? AND YEAR(cd_date)=?'
      when 'semester' then stmt += 'MONTH(cd_date) BETWEEN ? AND ? AND YEAR(cd_date)=?'
      when 'year'     then stmt += 'YEAR(cd_date)=?'
    end
    return stmt += " GROUP BY cd_#{grouper} ORDER BY cd_#{grouper}"
  end

  def getter_args(command)
    args = []
    offset = 0
    if(command.count > 2)
      offset = command[2].to_i.abs
      offset += 1 if command[2].eql?("last")
    end
    case command[1]
      when 'month'    then args = month_args(offset)
      when 'semester' then args = semester_args(offset)
      when 'year'     then args = [Time.now.year - offset]
    end
    return args
  end

  def valid_command?(command)
    command.match?(/\A~(totals|hills|roundoff)/)
  end

  def valid_args?(command)
    (command.count > 1 && ['month', 'semester', 'year'].include?(command[1]))
  end

  def header(command)
    header = '```'
    if((command[-1].to_i != 0) && command.count > 2)
      header << "#{command[1].capitalize} #{command[0][1..-1]} (-#{command[-1].to_i.abs})"
    else
      header << command[-1].capitalize
      command.reverse[1..-1].each {|c| header << " #{c.gsub('~', '')}"}
    end
    return header + ":\r\n"
  end

  def response(data, command)
    message = header(command)
    case command[0]
    when "~totals"
      all = Hash.new(0)
      data.each do |total|
        message << row(total, :cd_mph)
        total.keys.each {|key| all[key] += total[key]}
      end
      all[:cd_mph] = "ALL"
      message << row(all, :cd_mph)
    when "~hills"
      data.each{|total| message << row(total, :cd_incline)}
    when "~roundoff"
      data.each do |total|
        next if(total[:distance].to_f % 1 == 0)
        rtime, rdistance = round_off(total[:cd_mph].to_f, total[:minutes].to_i)
        message << "#{total[:cd_mph]}mph:  #{rtime} minutes to reach #{rdistance}\n"
      end
    end
    return message.chomp + '```'
  end

  def command_response(content, mysql)
    command, response = content.split(' '), ""
    return "Unknown command #{event.content}" unless valid_command?(command[0])
    return "Missing or unrecognized arguments for command `#{command[0]}`" unless valid_args?(command)
    mysql.execute(getter_statement(command), getter_args(command)) do |results|
      response = response(results, command)
    end
    return response
  end
end
