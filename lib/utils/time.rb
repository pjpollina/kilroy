# Project specific functions for the Time class

require 'time'

class Time
  # Returns the semester (half of the year) for time
  def semester
    (month < 7) ? 1 : 2
  end

  # Returns the month and year that was offset months before time
  def months_ago(offset)
    pmonth, pyear = (month - offset), year
    pmonth, pyear = pmonth + 12, pyear - 1 until pmonth > 0
    return pmonth, pyear
  end

  # Returns the semester and year that was offset months before time
  def semesters_ago(offset)
    psem, pyear = (semester - offset), year
    psem, pyear = psem + 2, pyear - 1 until psem > 0
    return psem, pyear
  end

  # Returns the number of days in the current month for time
  def month_days
    case month
    when 2
      return (Date.leap?(year)) ? 29 : 28
    when 4, 6, 9, 11
      return 30
    else
      return 31
    end
  end

  # Returns the first day of the week for time
  def week_start
    [1, 8, 15, 22, 29].select{|s| s <= day}.max
  end

  # Returns the final day of the week for time
  def week_end
    (week_start < 28) ? week_start + 6 : month_days
  end
end