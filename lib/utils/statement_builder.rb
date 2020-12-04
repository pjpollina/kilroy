# Class that builds SQL statements from templates based on conditions

class StatementBuilder
  def initialize(base, fillins={})
    @base    = base
    @fillins = fillins.each_value {|v| v.default = ""}
    unless(validate)
      raise ArgumentError.new("StatementBuilder fillins don't match params")
    end
  end

  def build(args={})
    stmt = @base
    params.each do |param|
      stmt = stmt.gsub(":#{param}", @fillins[param][args[param]])
    end
    return stmt
  end

  private

  def params
    @base.split(' ').select {|k| k.start_with?(':')}.collect{|k| k.gsub(':', '').chomp(',').to_sym}.uniq
  end

  def validate
    params.sort == @fillins.keys.sort
  end
end
