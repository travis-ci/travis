begin
  require 'travis/client'
rescue LoadError => e
  if e.message == 'no such file to load -- json'
    $stderr.puts "You should either run `gem install json` or upgrade your Ruby version!"
    exit 1
  else
    raise e
  end
end

require 'gh'
GH.set(:ssl => Travis::Client::Session::SSL_OPTIONS)

module Travis
  module CLI
    autoload :Token,        'travis/cli/token'
    autoload :ApiCommand,   'travis/cli/api_command'
    autoload :Command,      'travis/cli/command'
    autoload :Console,      'travis/cli/console'
    autoload :Disable,      'travis/cli/disable'
    autoload :Enable,       'travis/cli/enable'
    autoload :Encrypt,      'travis/cli/encrypt'
    autoload :Endpoint,     'travis/cli/endpoint'
    autoload :Help,         'travis/cli/help'
    autoload :History,      'travis/cli/history'
    autoload :Login,        'travis/cli/login'
    autoload :Logs,         'travis/cli/logs'
    autoload :Open,         'travis/cli/open'
    autoload :Parser,       'travis/cli/parser'
    autoload :Raw,          'travis/cli/raw'
    autoload :RepoCommand,  'travis/cli/repo_command'
    autoload :Restart,      'travis/cli/restart'
    autoload :Show,         'travis/cli/show'
    autoload :Status,       'travis/cli/status'
    autoload :Sync,         'travis/cli/sync'
    autoload :Version,      'travis/cli/version'
    autoload :Whatsup,      'travis/cli/whatsup'
    autoload :Whoami,       'travis/cli/whoami'

    extend self

    def windows?
      RUBY_PLATFORM =~ /mswin|mingw/
    end

    def run(*args)
      args, opts = preparse(args)
      name       = args.shift unless args.empty?
      command    = command(name).new(opts)
      command.parse(args)
      command.execute
    end

    def command(name)
      const_name = command_name(name)
      constant   = CLI.const_get(const_name) if const_name =~ /^[A-Z][a-z]+$/ and const_defined? const_name
      if command? constant
        constant
      else
        $stderr.puts "unknown command #{name}"
        exit 1
      end
    end

    def commands
      CLI.constants.map { |n| CLI.const_get(n) }.select { |c| command? c }
    end

    private

      def command?(constant)
        constant and constant < Command and not constant.abstract?
      end

      def command_name(name)
        case name
        when nil, '-h', '-?' then 'Help'
        when '-v'            then 'Version'
        when /^--/           then command_name(name[2..-1])
        else name.to_s.capitalize
        end
      end

      # can't use flatten as it will flatten hashes
      def preparse(unparsed, args = [], opts = {})
        case unparsed
        when Hash  then opts.merge! unparsed
        when Array then unparsed.each { |e| preparse(e, args, opts) }
        else args << unparsed.to_s
        end
        [args, opts]
      end
  end
end
