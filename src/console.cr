require "./record"
require "./commands/*"

module EazyDB
  COMMANDS = {
    /^create (?<args>.*)/ => Commands::Create,
    /^insert (?<args>.*)/ => Commands::Insert,
    /^get (?<args>.*)/    => Commands::Get,
    /^update (?<args>.*)/ => Commands::Update,
    /^delete (?<args>.*)/ => Commands::Delete,
    /^dump$/              => Commands::Dump,
    /^reindex$/           => Commands::Reindex,
    /^purge$/             => Commands::Purge,
    /^info$/              => Commands::Info,
  }

  class Console
    @db : Record::Record?
    @db_name : String?

    def initialize(@interactive = true)
    end

    def run
      loop do
        line = prompt
        break if line.nil?
        line = line.chomp
        break if line == "exit" || line == "quit"
        if line.starts_with?("use")
          _, path = line.split(' ')
          @db_name = path
          start = Time.monotonic
          res = use(path)
          e = Time.monotonic
          report(res, e - start)
          next
        end

        found = COMMANDS.each do |regex, klass|
          m = regex.match line
          if m
            cmd = klass.new(@db)
            start = Time.monotonic
            res = cmd.run(m["args"]?)
            e = Time.monotonic
            report(res, e - start)
            break :found
          end
        end

        puts line if found != :found
      end
    end

    def report(res : Commands::Response, time : Time::Span)
      if @interactive
        puts res.to_s
        puts "Time: #{time}"
      else
        res.time = time
        puts res.to_json
      end
    end

    def prompt
      return gets unless @interactive

      if @db_name
        Readline.readline("(#{@db_name})> ")
      else
        Readline.readline("> ")
      end
    end

    def use(path)
      @db = ::EazyDB::Record::Record.new(path)
      Commands::SuccessResponse.new("Use #{path}")
    end
  end
end
