require "readline"
require "commander"
require "./console"

cli = Commander::Command.new do |cmd|
  cmd.use = "eazydb"
  cmd.long = "eazydb"

  cmd.flags.add do |flag|
    flag.name = "interactive"
    flag.short = "-i"
    flag.long = "--interactive"
    flag.default = false
    flag.description = "Interactive mode"
  end

  cmd.run do |options, arguments|
    if options.bool["interactive"]
      EazyDB::Console.new.run
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "create"
    cmd.short = "Create database"
    cmd.long = cmd.short
    cmd.run do |options, arguments|
      p options
      p arguments
    end
  end
end

Commander.run(cli, ARGV)

