# Functional programming-centric interface for MySQL database

require 'mysql2'

class MySQL
  def initialize(username, password, database, host="localhost")
    @username = username
    @password = password
    @database = database
    @host     = host
  end

  def connect
    client = new_client
    yield(client)
    client.close
  end

  def execute(statement, args)
    connect do |client|
      stmt = client.prepare(statement)
      results = stmt.execute(*args, symbolize_keys: true)
      yield(results) if block_given?
      stmt.close
    end
  end

  private

  def new_client
    Mysql2::Client.new(username: @username, password: @password, database: @database, host: @host)
  end
end
