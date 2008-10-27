require 'rubygems'
require 'metaid'

# Required by fetchers
require 'mechanize'
require 'active_support'

module BankJob
  VERSION = '1.0.0'

  class Fetcher
    @@fetchers = []
    @@meta = {}

    # class methods
    class << self
      # name, description
      def needs(*args)
        p = meta_def :needs do |*args|
          @needs ||= []
          args.empty? ? @needs : @needs << [*args]
        end
        p.call(*args)
      end

      %w(institution description ofx_fid).each do |m|
        define_method m do |*args|
          p = meta_def m do |*args|
            @meta ||= {}
            args.empty? ? @meta[m] : @meta[m] = args.first
          end
          p.call(*args)
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
      meta_eval { attr_reader(*(opts.keys & my_needs)) }
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end

require File.join(File.dirname(__FILE__), 'ofx_client')

Dir.glob(File.join(File.dirname(__FILE__), 'fetchers', '*')).each do |fn|
  require fn if fn =~ /[.]rb$/
end
