require 'rubygems'

# Required by fetchers
require 'mechanize'
require 'active_support'
require 'active_support/core_ext'

module BankJob
  VERSION = '1.0.0'

  class Fetcher
    @@fetchers = []

    # class methods
    class << self
      # name, description
      def needs(*args)
        (@__needs ||= []) << [*args] unless args.empty?
        @__needs
      end

      %w(institution description ofx_fid).each do |m|
        define_method m do |*args|
          instance_variable_set("@__#{m}", args.first) unless args.empty?
          instance_variable_get("@__#{m}") if instance_variable_defined?("@__#{m}")
        end
      end

      def institution_type
        parent.to_s.demodulize.downcase.to_sym
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

  [:cc, :bank, :invest].each do |t|
    const_set(t.to_s.capitalize, Class.new(self.class))
  end

  class << self
    @@disabled = []
    def disabled; @@disabled; end
    def disabled?(str); @@disabled.include?(str); end
  end

end

require File.join(File.dirname(__FILE__), 'ofx_client')

Dir.glob(File.join(File.dirname(__FILE__), 'fetchers', '*')).each do |fn|
  require fn if fn =~ /[.]rb$/ && fn !~ /autogen/
end

# always require autogen last.
require File.join(File.dirname(__FILE__), 'fetchers', 'autogen')
