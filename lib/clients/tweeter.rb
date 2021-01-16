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
    minutes, distance, topspeed, topminutes = totals(mysql, "cd_date=CURDATE()")
    return tweet("I ran #{distance} miles in #{minutes} minutes today, top run was #{topminutes} minutes at #{topspeed}mph")
  end

  # Gets this week's run stats using mysql, formats them, tweets it, and returns the tweet's URL
  def week_totals(mysql)
    minutes, distance, topspeed, topminutes = totals(mysql, "cd_date BETWEEN #{Time.now.week.collect{|t| t.sql_date}.join(" AND ")}")
    return tweet("I ran #{distance} miles in #{minutes} minutes this week, top run was #{topminutes} minutes at #{topspeed}mph")
  end

  # Gets this month's run stats using mysql, formats them, tweets it, and returns the tweet's URL
  def month_totals(mysql)
    minutes, distance, topspeed, topminutes = totals(mysql, "THIS_MONTH(cd_date)")
    return tweet("I ran #{distance} miles in #{minutes} minutes this month, top run was #{topminutes} minutes at #{topspeed}mph")
  end

  private

  # Returns the values needed for totals tweets using mysql and condition
  def totals(mysql, condition)
    minutes, distance, topspeed, topminutes = 0, 0.0, 0.0, 0
    mysql.execute("SELECT * FROM cardio WHERE #{condition}") do |runs|
      runs.each do |run|
        minutes += run[:cd_minutes].to_i
        distance += run[:cd_distance].to_f.round(3)
        if(run[:cd_mph].to_f.round(1) > topspeed)
          topspeed = run[:cd_mph].to_f.round(1)
          topminutes = run[:cd_minutes].to_i
        end
      end
    end
    return minutes, distance, topspeed, topminutes
  end
end
