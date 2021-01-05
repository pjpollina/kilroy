# Functions related to messages in the status channel

module Status
  extend self

  def query(command)
    "CALL #{command[1].upcase}_RUNS(#{args(command).join(", ")})"
  end

  def args(command)
    offset = command[2].to_i.abs + (command[2].eql?("last") ? 1 : 0)
    case command[1]
      when 'month'    then return month_args(offset)
      when 'semester' then return semester_args(offset)
      when 'year'     then return [Time.now.year - offset]
      else return []
    end
  end

  def month_args(offset=0)
    date = (Date.today - (Date.today.day - 1)) << offset
    return date.month, date.year
  end

  def semester_args(offset=0)
    month = Time.now.month - ((Time.now.month < 7) ? 1 : 7)
    sem, year = month_args(month + (offset * 6))
    return ((sem == 1) ? 1 : 2), year
  end

  def round_off(total)
    return "" if (total[:distance].to_f % 1 == 0)
    speed, time = total[:speed].to_f, total[:minutes].to_i
    roundtime = 30 - (time % 30)
    rounddistance = (speed / 60) * (time + roundtime)
    until(rounddistance % 1 == 0)
      roundtime += 30
      rounddistance = (speed / 60) * (time + roundtime)
    end
    return "#{speed}mph:  #{roundtime} minutes to reach #{rounddistance}\n"
  end

  def row(total)
    row = "#{total[:speed].to_s.ljust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(5)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\n"
    return row
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
      all = Hash.new(0)
      data.each do |total|
        total.keys.each {|key| all[key] += total[key]}
        message << row(total)
      end
      all[:speed] = "ALL"
      message << row(all)
    when "~roundoff"
      message << data.collect {|total| round_off(total)}.join
    end
    return message + "```"
  end

  def response(content, mysql)
    command, response = content.split(' '), ""
    return "Unknown command #{content}" unless command[0].match?(/\A~(totals|roundoff)/)
    return "Missing or unrecognized arguments for command `#{command[0]}`" unless ['month', 'semester', 'year'].include?(command[1])
    mysql.execute(query(command)) do |results|
      response = run_data(results, command)
    end
    return response, "Command issued: #{content}"
  end
end
