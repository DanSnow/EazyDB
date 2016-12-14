require "./base"

module EazyDB::Operations
  class Get < Base
    def execute(*args : *String)
      id = args[0]
    end
  end
end
