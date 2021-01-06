# Functions related to backing up queries to an SQL file

require 'aws-sdk-s3'
require 'lib/utils/time'

module Backup
  extend self

  ROOT = ENV['backup_dir']

  def header(month, day, year=Time.now.year)
    time = Time.new(year, month, day)
    time.strftime("-- %b #{[time.week_start, time.week_end].uniq.join("-")}\n")
  end

  def filepath(root=ROOT)
    File.expand_path(Time.now.strftime("#{root}/%Y/%m%B.sql"))
  end

  def query(mph, minutes, incline="", date: Time.now)
    query = "INSERT INTO cardio(cd_date, cd_mph, cd_minutes"
    query << ((incline.empty?) ? ")#{" " * 13}" : ", cd_incline) ")
    query << "VALUES('#{date.strftime("%F")}', #{mph.rjust(4)}, #{minutes.chomp(?m).rjust(2)}"
    query << ((incline.empty?) ? ");" : ", #{incline.chomp('%')});")
    return query
  end

  def write(mph, minutes, incline="", date: Time.now)
    Dir.mkdir(File.dirname(filepath)) unless Dir.exist?(File.dirname(filepath))
    File.open(filepath, 'a+') do |file|
      unless(file.readlines.include?(header(date.month, date.day)))
        file.puts header(date.month, date.day)
      end
      file.puts query(mph, minutes, incline, date: date)
    end
  end

  def s3_sync
    bucket, root = ENV['s3_backup_dir'].split('/')
    File.open(Backup.filepath, 'r') do |file|
      s3_client.put_object(bucket: bucket, key: root + Backup.filepath(""), body: file)
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
