# Functional programming-centric interface for MySQL database

require 'mysql2'

class MySQL
  # Creates a new MySQL object, defaulting to the intended parameters
  def initialize(username="kilroy", password=ENV['discord_bot_token'], database="fitness", host=ENV['sql_host'])
    @username = username
    @password = password
    @database = database
    @host     = host || "localhost"
  end

  # Connects to MySQL and yields the client object, closing it afterwards
  def connect
    client = new_client
    yield(client)
    client.close
  end

  # Prepares and executes the given statement with args, yields the results, then closes it
  def execute(statement, args=[])
    connect do |client|
      stmt = client.prepare(statement)
      results = stmt.execute(*args, symbolize_keys: true)
      yield(results) if block_given?
      stmt.close
    end
  end

  private

  # Creates a new Mysql2 client using this object's attributes
  def new_client
    Mysql2::Client.new(username: @username, password: @password, database: @database, host: @host)
  end
end
