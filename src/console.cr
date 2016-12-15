require "./commands/*"

module EazyDB
  COMMANDS = {
    /^create (?<args>.*)/ => Commands::Create
  }
  class Console
    def run
      loop do
        line = Readline.readline("> ")
        break if line.nil?
        line = line.chomp
        break if line == "exit" || line == "quit"
        found = COMMANDS.each do |regex, klass|
          m = regex.match line
          if m
            cmd = klass.new
            cmd.run(m["args"])
            break :found
          end
        end

        puts line if found != :found
      end
    end
  end
end
