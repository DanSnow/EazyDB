module EazyDB::Operations
  abstract class Base
    def initialize(@meta)
    end

    def run(*args : *String)
      execute(*args)
    end

    abstract def execute(*args : *String)
  end
end
