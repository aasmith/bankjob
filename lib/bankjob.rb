require 'rubygems'

# Required by fetchers
require 'mechanize'
require 'active_support'

module BankJob
  VERSION = '1.0.0'

  class Fetcher
    @@fetchers = []

    # class methods
    class << self
      # name, description
      def needs(*args)
        (@__needs ||= []) << [*args]
        @__needs
      end

      %w(institution description ofx_fid).each do |m|
        define_method m do |*args|
          instance_variable_set("@__#{m}", args.first) unless args.empty?
          instance_variable_get("@__#{m}")
        end
      end

      def inherited(c)
        @@fetchers << c
      end

      def fetchers; @@fetchers; end

      def find(opts)
        fetchers.detect do |f| 
          opts.all? do |k,v|
            f.send(k.to_sym) == v rescue nil
          end
        end
      end
    end

    # instance methods
    def initialize(opts)
      my_needs = self.class.needs.map{|a|a.first}

      self.class.instance_eval do
        (opts.keys & my_needs).each do |var|
          define_method var do
            instance_variable_get("@__#{var}")
          end

        end
      end

      (opts.keys & my_needs).each do |var|
        instance_variable_set("@__#{var}", opts[var])
      end
    end
  end
end

require File.join(File.dirname(__FILE__), 'ofx_client')

Dir.glob(File.join(File.dirname(__FILE__), 'fetchers', '*')).each do |fn|
  require fn if fn =~ /[.]rb$/
end
