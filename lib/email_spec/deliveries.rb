module EmailSpec

  module Deliveries

    # This module contains deprecated methods for backwards compatibility.
    # They will be removed at some point in the future.
    module Deprecated
      def all_emails
        puts "WARNING: Using #all_emails is deprecated. Use #all instead."
        all
      end

      def reset_mailer
        puts "WARNING: Using #reset_mailer is deprecated. Use #reset instead."
        reset
      end

      def parse_to_mail(mail)
        puts "WARNING: Using #parse_to_mail is deprecated. Use #parse instead."
        parse mail
      end

      def last_email_sent
        puts "WARNING: Using #last_email_sent is deprecated. Use #last instead."
        last
      end

      def mailbox_for(address)
        puts "WARNING: Using #mailbox_for is deprecated. Use #by_recipient instead."
        by_recipient address
      end
    end

    class Base
      include Deprecated

      def all
        raise "Not implemented"
      end
     
      # Returns the last sent mail or nil if there is none.
      def last
        raise "Not implemented"
      end

      def reset
        raise "Not implemented"
      end

      def by_recipient(address)
        all.select { |email|
          (email.to && email.to.include?(address)) ||
          (email.bcc && email.bcc.include?(address)) ||
          (email.cc && email.cc.include?(address)) }
      end

      def parse(mail)
        Mail.read mail
      end
    end

    # For ActionMailer with delivery_method = :test
    class Test < Base

      def all
        ActionMailer::Base.deliveries
      end

      def last
        ActionMailer::Base.deliveries.last
      end

      def reset
        ActionMailer::Base.deliveries.clear
      end

    end

    # For ActionMailer with delivery_method = :cache
    class Cache < Base

      def all
        ActionMailer::Base.cached_deliveries
      end

      def last
        ActionMailer::Base.cached_deliveries.last
      end

      def reset
        ActionMailer::Base.clear_cache
      end

    end

    # For ActionMailer with delivery_method = :file
    class File < Base

      attr_accessor :root

      def initialize(options)
        raise "You need to pass the :root option." unless options[:root]
        self.root = options[:root] 
      end

      def all
        Dir["#{root}/*"].map { |file| parse(File.read file) }
      end

      def last
        raise "Pending"
        all.sort
      end

      def reset
        FileUtils.rm "#{root}/*"
      end
    end

    # For ActionMailer with delivery_method = :activerecord
    class ARMailer

      attr_accessor :model

      def initialize(options)
        self.model = options[:model]
      end


      def all
        model.all.map { |email| parse email.mail }
      end

      def last
        if email = model.last
          parse mail
        end
      end

      def reset
        model.delete_all
      end

    end

    # Using Pony
    class Pony < Base

      def all
        ::Pony.deliveries
      end

      def last
        ::Pony.deliveries.last
      end

      def reset
        ::Pony.deliveries.clear
      end

    end

    def all_emails
      EmailSpec.adapter.all
    end

    def reset_mailer
      EmailSpec.adapter.reset
    end

    def mailbox_for(address)
      EmailSpec.adapter.by_recipient address
    end

  end

end

# Monkey-patch pony to not really send mails but store them.
if defined?(Pony)
  module ::Pony
    def self.deliveries
      @deliveries ||= []
    end

    def self.mail(options)
      deliveries << build_mail(options)
    end
  end
end
