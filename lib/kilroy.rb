# Wrapper class for bot parts

class Kilroy
  attr_reader :discord, :mysql, :tweeter

  def initialize(clients={})
    @discord = clients[:discord]
    @mysql   = clients[:mysql]
    @tweeter = clients[:tweeter]
  end

  def message(attributes={}, &block)
    discord.message(attributes, &block)
  end

  def run
    discord.run
  end
end
