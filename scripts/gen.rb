require 'rubygems'
require 'nokogiri'
require 'active_support'

spec = ARGV[0] || "fidata/fi/*.xml"
generated = []

Dir.glob(spec).each do |fn|
  #puts fn

  xml = File.read(fn)
  doc = Nokogiri::XML(xml)
  
  url = CGI.unescapeHTML(doc.search('ProviderURL').text)

  # skip if no url, or yodlee
  next if url.empty? || url =~ /DataFeedAPI/

  # capture details, setting strings that contain just whitespace to empty.
  fiorg = doc.search('Org').text.gsub(/\A\s+\Z/m,'')
  fid   = doc.search('FID').text.gsub(/\A\s+\Z/m,'')
  name  = doc.search('Name').text.gsub(/\A\s+\Z/m,'')


  brokerid = doc.search('BrokerID').text

  # capabilities
  c = {}
  c[:bank]   = doc.search('Bank').text.to_i
  c[:invest] = doc.search('BrkStmt').text.to_i
  c[:cc]     = doc.search('CreditCard').text.to_i


  c.each do |k,v|
    if v == 1
      class_name = "Autogen#{name.scan(/[0-9A-Za-z]*/).to_s.camelize}"
      #puts " generating #{class_name}"
      
      p = "#{k.to_s.capitalize}::#{class_name}"
      next if generated.include?(p)

      generated << p

      code = <<-EOS
# Generated from #{fn}
class BankJob::#{k.to_s.capitalize}::#{class_name} < BankJob::Fetcher
  URL = "#{url}"

  needs :username
  needs :password
  needs :account_number

  institution "#{name}"
  ofx_fid "#{fid}"

  def initialize(args)
    super

    @ofx_client = BankJob::OfxClient.new(
      :user     => username,
      :pass     => password,
      :fiorg    => "#{fiorg}",
      :fid      => self.class.ofx_fid, #{"\n      :brokerid => '#{brokerid}'," if k == :invest}
      :url      => URL)
  end

  def fetch
    @ofx_client.fetch(
      :type  => self.class.institution_type,
      :start => 90.days.ago,
      :acct  => account_number
    )
  end

  def list
    @ofx_client.list
  end
end
      EOS

      puts code
      
    end
  end
end
