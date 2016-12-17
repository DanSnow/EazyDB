require "./record"
require "./commands/*"

module EazyDB
  COMMANDS = {
    /^create (?<args>.*)/ => Commands::Create,
    /^insert (?<args>.*)/ => Commands::Insert,
    /^info$/ => Commands::Info
  }
  class Console
    def run
      db = nil
      db_name = nil
      loop do
        line = if db_name
                 Readline.readline("(#{db_name})> ")
               else
                 Readline.readline("> ")
               end
        break if line.nil?
        line = line.chomp
        break if line == "exit" || line == "quit"
        if line.starts_with?("use")
          _, path =  line.split(' ')
          db_name = path
          db = use(path)
          next
        end

        found = COMMANDS.each do |regex, klass|
          m = regex.match line
          if m
            cmd = klass.new(db)
            cmd.run(m["args"]?)
            break :found
          end
        end

        puts line if found != :found
      end
    end

    def use(path)
      puts "Use #{path}"
      ::EazyDB::Record::Record.new(path)
    end
  end
end
