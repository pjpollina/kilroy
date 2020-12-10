# Functions related to backing up queries to an SQL file

require 'aws-sdk-s3'

module Backup
  extend self

  ROOT = ENV['backup_dir']

  def header(month, day)
    startday = day
    startday -= 1 until([1, 8, 15, 22, 29].include?(startday))
    if(startday != 29)
      return "-- #{Time.new(2000, month, startday).strftime("%b %-d")}-#{startday + 6}\n"
    else
      headers = ["Jan 29-31", "Feb 29", "Mar 29-31", "Apr 29-30", "May 29-31", "Jun 29-30", "Jul 29-31", "Aug 29-31", "Sep 29-30", "Oct 29-31", "Nov 29-30", "Dec 29-31"]
      return "-- #{headers[month - 1]}\n"
    end
  end

  def filepath(root=ROOT)
    File.expand_path(Time.now.strftime("#{root}/%Y/%m%B.sql"))
  end

  def query(mph, minutes, incline="")
    query = "INSERT INTO cardio(cd_date, cd_mph, cd_minutes"
    query << ((incline.empty?) ? ")#{" " * 13}" : ", cd_incline) ")
    query << "VALUES('#{Time.now.strftime("%F")}', #{(mph.to_f >= 10.0) ? "" : " "}#{mph}, #{minutes.chomp(?m)}"
    query << ((incline.empty?) ? ");" : ", #{incline.chomp('%')});")
    return query
  end

  def write(mph, minutes, incline="")
    File.open(filepath, 'a+') do |file|
      unless(file.readlines.include?(header(Time.now.month, Time.now.day)))
        file.puts header(Time.now.month, Time.now.day)
      end
      file.puts query(mph, minutes, incline)
    end
  end

  private

  def s3_client
    Aws::S3::Client.new(
      access_key_id: ENV['s3_access_id'],
      secret_access_key: ENV['s3_access_secret'],
      region: ENV['s3_region']
    )
  end
end
