require "./record"
require "./commands/*"

module EazyDB
  COMMANDS = {
    /^create (?<args>.*)/ => Commands::Create,
    /^insert (?<args>.*)/ => Commands::Insert
  }
  class Console
    def run
      db = nil
      loop do
        line = Readline.readline("> ")
        break if line.nil?
        line = line.chomp
        break if line == "exit" || line == "quit"
        if line.starts_with?("use")
          db = use(line)
          next
        end

        found = COMMANDS.each do |regex, klass|
          m = regex.match line
          if m
            cmd = klass.new(db)
            cmd.run(m["args"])
            break :found
          end
        end

        puts line if found != :found
      end
    end

    def use(line)
      _, path =  line.split(' ')
      puts "Use #{path}"
      ::EazyDB::Record::Record.new(path)
    end
  end
end
