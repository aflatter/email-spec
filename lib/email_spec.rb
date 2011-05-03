unless defined?(Pony) or defined?(ActionMailer)
  Kernel.warn("Neither Pony nor ActionMailer appear to be loaded so email-spec is requiring ActionMailer.")
  require 'action_mailer'
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))) unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

module EmailSpec
  def self.default_adapter
    return self.adapter = :Pony if defined?(Pony)

    unless defined?(ActionMailer)
      Kernel.warn "email_spec: Neither Pony nor ActionMailer are loaded. Requiring ActionMailer."
      require 'action_mailer'
    end

    case ActionMailer::Base.delivery_method
    when :cache
      self.adapter = :Cache
    when :activerecord
      self.adapter = :ARMailer
    when :test
      self.adapter = :Test
    when :file
      self.adapter = :File
    else
      raise "I don't know what to do with delivery_method" +
            " '#{ActionMailer::Base.delivery_method}'."
    end
  end

  def self.adapter=(value)
    if value.is_a?(Symbol)
      @adapter = EmailSpec::Deliveries.const_get(value).new(self.options)
    else
      @adapter = value
    end
  end

  def self.adapter
    @adapter || self.adapter = self.default_adapter
    @adapter
  end

  def self.options=(options)
    @options = options
  end

  def self.options
    @options || {}
  end
end

require 'rspec'
require 'email_spec/background_processes'
require 'email_spec/deliveries'
require 'email_spec/address_converter'
require 'email_spec/email_viewer'
require 'email_spec/helpers'
require 'email_spec/matchers'
require 'email_spec/mail_ext'
