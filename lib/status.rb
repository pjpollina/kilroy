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

  def total_row(total)
    row = "#{total[:cd_mph].to_s.ljust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(5)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\r\n"
    return row
  end

  def hills_row(total)
    row = "#{total[:cd_incline].to_s.rjust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(4)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\r\n"
    return row
  end

  def getter_statement(command)
    stmt, grouper = "", ""
    case command[0]
    when "~totals"
      stmt = 'SELECT cd_mph, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE '
      grouper = 'mph'
    when "~hills"
      stmt = 'SELECT cd_incline, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE cd_mph=4.0 AND '
      grouper = 'incline'
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

  def response(data, command)
    message = "```#{command[1].capitalize} #{command[0][1..-1]}:\r\n"
    case command[0]
    when "~totals"
      all = Hash.new(0)
      data.each do |total|
        message << total_row(total)
        total.keys.each {|key| all[key] += total[key]}
      end
      all[:cd_mph] = "ALL"
      message << total_row(all)
    when "~hills"
      data.each{|total| message << hills_row(total)}
    end
    return message + '```'
  end
end
