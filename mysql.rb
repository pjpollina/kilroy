# Functional programming-centric interface for MySQL database

require 'mysql2'

class MySQL
  def initialize(username, password, database, host=localhost)
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

  private

  def new_client
    Mysql2::Client.new(username: @username, password: @password, database: @database, host: @host)
  end
end
