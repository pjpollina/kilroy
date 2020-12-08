# Functions relating to adding cardio

module Cardio
  extend self

  REG_RUN  = /\A([1-9]|[1-9][0-9])\.(0|5), ([1-9]|[1-5][0-9]|60)m\z/
  REG_HILL = /#{REG_RUN.source.chomp('\z')}, ([1-9]|[1-9][0-9])\.(0|5)%\z/

  INSERT_RUN  = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes) VALUES(CURDATE(), ?, ?)'
  INSERT_HILL = 'INSERT INTO cardio(cd_date, cd_mph, cd_minutes, cd_incline) VALUES(CURDATE(), ?, ?, ?)'

  def valid?(command)
    /#{REG_RUN.source.chomp('\z')}(?:, [1-9]\.[0-9]%)?/.match?(command)
  end

  def argparse(command)
    mph, minutes, incline = command.split(', ')
    args = [mph.to_f, minutes.chomp('m').to_i]
    args << incline.chomp('%').to_f unless incline.nil?
    return args
  end

  def statement(command)
    case command
      when REG_RUN  then return INSERT_RUN
      when REG_HILL then return INSERT_HILL
      else return nil
    end
  end

  def insert(command, mysql)
    return "Unrecognized cardio format", true unless valid?(command)
    mysql.execute(statement(command), argparse(command))
    Backup.write(*command.split(', '))
    return "Run logged: #{command}", false
  end
end
