# Class that handles all Twitter functionality

require 'twitter'

class Tweeter
  # The footer string for all tweets
  FOOTER = "(via Kilroy)"

  # Creates a new Tweeter object, with a Twitter client using the credentials from .env
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['twitter_api_key']
      config.consumer_secret     = ENV['twitter_api_secret']
      config.access_token        = ENV['twitter_access_token']
      config.access_token_secret = ENV['twitter_access_secret']
    end
  end

  # Tweets a given message with footer and returns the new tweet's URL
  def tweet(message, footer=FOOTER)
    @client.update("#{message} #{footer}").url
  end

  # Gets today's run stats using mysql, formats them, tweets it, and returns the tweet's URL
  def day_totals(mysql)
    mysql.execute("SELECT * FROM cardio WHERE cd_date=CURDATE()") do |runs|
      minutes, distance, topspeed, topminutes = 0, 0.0, 0.0, 0
      runs.each do |run|
        minutes += run[:cd_minutes].to_i
        distance += run[:cd_distance].to_f.round(3)
        if(run[:cd_mph].to_f.round(1) > topspeed)
          topspeed = run[:cd_mph].to_f.round(1)
          topminutes = run[:cd_minutes].to_i
        end
      end
      return tweet("I ran #{distance} miles in #{minutes} minutes today, top run was #{topminutes} minutes at #{topspeed}mph")
    end
  end

  # Gets this week's run stats using mysql, formats them, tweets it, and returns the tweet's URL
  def week_totals(mysql)
    time = Time.now
    cond = time.strftime("'%Y-%m-#{"%02d" % time.week_start}' AND '%Y-%m-#{"%02d" % time.week_end}'")
    mysql.execute("SELECT * FROM cardio WHERE cd_date BETWEEN #{cond}") do |runs|
      minutes, distance, topspeed, topminutes = 0, 0.0, 0.0, 0
      runs.each do |run|
        minutes += run[:cd_minutes].to_i
        distance += run[:cd_distance].to_f.round(3)
        if(run[:cd_mph].to_f.round(1) > topspeed)
          topspeed = run[:cd_mph].to_f.round(1)
          topminutes = run[:cd_minutes].to_i
        end
      end
      return tweet("I ran #{distance} miles in #{minutes} minutes this week, top run was #{topminutes} minutes at #{topspeed}mph")
    end
  end
end
