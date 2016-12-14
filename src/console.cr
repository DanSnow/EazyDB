require "./commands/*"

module EazyDB
  class Console
    def run
      loop do
        line = Readline.readline("> ")
        break if line.nil?
        line = line.chomp
        case line
        when "exit", "quit"
          break
        when /^create/
          m = line.match(/^create (?<path>\S+)/).not_nil!
          if m
            path = m["path"]
            cmd = Commands::Create.new
            cmd.run(path)
          else
            STDERR.puts "Syntax error"
          end
        else
          puts line
        end
      end
    end
  end
end
