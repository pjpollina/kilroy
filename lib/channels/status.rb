# Functions related to messages in the status channel

require 'lib/utils/statement_builder'

module Status
  extend self

  GET_TOTALS = StatementBuilder.new(
    "SELECT :prime AS prime, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance FROM cardio WHERE :cond GROUP BY prime ORDER BY prime",
    prime: {"~totals" => "cd_mph", "~hills" => "cd_incline", "~roundoff" => "cd_mph"},
    cond:  {
      "month"    => 'MONTH(cd_date)=? AND YEAR(cd_date)=?',
      "semester" => 'MONTH(cd_date) BETWEEN ? AND ? AND YEAR(cd_date)=?',
      "year"     => 'YEAR(cd_date)=?'
    }
  )

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

  def round_off(total)
    return "" if (total[:distance].to_f % 1 == 0)
    speed, time = total[:cd_mph].to_f, total[:minutes].to_i
    roundtime = 30 - (time % 30)
    rounddistance = (speed / 60) * (time + roundtime)
    until(rounddistance % 1 == 0)
      roundtime += 30
      rounddistance = (speed / 60) * (time + roundtime)
    end
    return "#{speed}mph:  #{roundtime} minutes to reach #{rounddistance}\n"
  end

  def row(total)
    row = "#{total[:prime].to_s.ljust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(5)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\n"
    return row
  end

  def table(data, do_all=true)
    table, all = "", Hash.new(0)
    data.each do |total|
      table << ((block_given?) ? yield(total) : row(total))
      total.keys.each {|key| all[key] += total[key]}
    end
    all[:prime] = "ALL"
    table << row(all) if do_all
    return table
  end

  def getter_args(command)
    offset = command[2].to_i.abs + (command[2].eql?("last") ? 1 : 0)
    case command[1]
      when 'month'    then return month_args(offset)
      when 'semester' then return semester_args(offset)
      when 'year'     then return [Time.now.year - offset]
      else return []
    end
  end

  def header(command)
    header = "```\n"
    if((command[-1].to_i != 0) && command.count > 2)
      header << "#{command[1].capitalize} #{command[0][1..-1]} (-#{command[-1].to_i.abs})"
    else
      header << command[-1].capitalize
      command.reverse[1..-1].each {|c| header << " #{c.gsub('~', '')}"}
    end
    return header + ":\n"
  end

  def run_data(data, command)
    message = header(command)
    case command[0]
    when "~totals"
      message << table(data)
    when "~hills"
      message << table(data, false)
    when "~roundoff"
      message << table(data, false) {|total| round_off(total)}
    end
    return message + "```"
  end

  def response(content, mysql)
    command, response = content.split(' '), ""
    return "Unknown command #{event.content}" unless command[0].match?(/\A~(totals|hills|roundoff)/)
    return "Missing or unrecognized arguments for command `#{command[0]}`" unless ['month', 'semester', 'year'].include?(command[1])
    mysql.execute(GET_TOTALS.build(prime: command[0], cond: command[1]), getter_args(command)) do |results|
      response = run_data(results, command)
    end
    return response
  end
end
