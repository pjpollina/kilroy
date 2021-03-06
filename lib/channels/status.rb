# Functions related to messages in the status channel

require 'lib/utils/time'

module Status
  extend self

  # Returns the appropriate SQL query for the given command
  def query(command)
    "CALL #{command[1].upcase}_RUNS(#{args(command).join(", ")})"
  end

  # Returns the proper SQL args for the given command
  def args(command)
    offset = command[2].to_i.abs + (command[2].eql?("last") ? 1 : 0)
    case command[1]
      when 'day'      then return [Time.now.days_ago(offset).sql_date]
      when 'week'     then return Time.now.weeks_ago(offset).collect{|w| w.sql_date}
      when 'month'    then return Time.now.months_ago(offset)
      when 'semester' then return Time.now.semesters_ago(offset)
      when 'year'     then return [Time.now.year - offset]
      else return []
    end
  end

  # Returns the results for the roundoff command for the given row
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

  # Returns a formatted string of the given row for the totals command
  def row(total)
    row = "#{total[:speed].to_s.ljust(4)}\t"
    row << "#{total[:minutes].to_i.to_s.rjust(5)}\t"
    row << "#{("%.3f" % total[:distance].round(3)).rjust(7)}\n"
    return row
  end

  # Returns an appropriate header string for the response to the given command
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

  # Returns the formatted response message for the given command using the SQL result data
  def run_data(data, command)
    message = header(command)
    case command[0]
    when "~totals"
      message << data.collect {|total| row(total)}.join
    when "~roundoff"
      message << data.collect {|total| round_off(total)}.join
    end
    return message + "```"
  end

  # Parses a given command and returns the appropriate response and log string
  def response(content, mysql)
    command, response = content.split(' '), ""
    return "Unknown command #{content}" unless command[0].match?(/\A~(totals|roundoff)/)
    return "Missing or unrecognized arguments for command `#{command[0]}`" unless ['day', 'week', 'month', 'semester', 'year'].include?(command[1])
    mysql.execute(query(command)) do |results|
      response = run_data(results, command)
    end
    return response, "Command issued: #{content}"
  end
end
