require 'travis/cli'
require 'travis/tools/notification'

module Travis
  module CLI
    class Monitor < ApiCommand
      description "live monitor for what's going on"
      on('-m', '--my-repos', 'Only monitor my own repositories')

      on('-r', '--repo SLUG', 'monitor given repository (can be used more than once)') do |c, slug|
        c.repos << slug
      end

      types = Tools::Notification::DEFAULT.map(&:to_s).join(", ")
      on('-n', '--[no-]notify [TYPE]', "send out desktop notifications (optional type: #{types})") do |c, type|
        c.setup_notification(type)
      end

      attr_reader :repos, :notification

      def initialize(*)
        @repos = []
        super
      end

      def setup
        super
        repos.map! { |r| repo(r) }
        repos.concat(user.repositories) if my_repos?
        setup_notification(repos.any? || :dummy) unless notification
      end

      def setup_notification(type = nil)
        refuse = false
        case type
        when false     then @notification = Tools::Notification.new(:dummy)
        when nil, true then @notification = Tools::Notification.new
        else
          refuse        = true
          @notification = Tools::Notification.new(type)
        end
      rescue ArgumentError => e
        @notification = Tools::Notification.new(:dummy)
        error(e.message) if refuse
        warn(e.message)
      end

      def description
        case repos.size
        when 0 then session.config['host']
        when 1 then repos.first.slug
        else "#{repos.size} repositories"
        end
      end

      def run
        listen(*repos) do |listener|
          listener.on_connect { say description, 'Monitoring %s:' }
          listener.on 'build:started', 'job:started', 'build:finished', 'job:finished' do |event|
            entity = event.job          || event.build
            time   = entity.finished_at || entity.started_at
            say [
              color(formatter.time(time), entity.color),
              color(entity.inspect_info, [entity.color, :bold]),
              color(entity.state, entity.color)
            ].join(" ")
            notification.notify("Travis CI", "#{entity.inspect_info} #{entity.state}")
          end
        end
      end
    end
  end
end
