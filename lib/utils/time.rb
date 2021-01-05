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
end
