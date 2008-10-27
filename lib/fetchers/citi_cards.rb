class BankJob::CitiCards < BankJob::Fetcher
  URL = "https://secureofx2.bankhost.com/citi/cgi-forte/ofx_rt?servicename=ofx_rt&pagename=ofx"

  needs :username
  needs :password
  needs :account_number, "Last four digits of the credit card number."

  institution "Citigroup"
  ofx_fid 24909

  def initialize(args)
    super

    @ofx_client = BankJob::OfxClient.new(
      :user  => username,
      :pass  => password,
      :fiorg => self.class.institution,
      :fid   => self.class.ofx_fid,
      :url   => URL
    )
  end

  def fetch
    @ofx_client.fetch(
      :type  => :cc,
      :start => 90.days.ago,
      :acct  => "X"*12 + account_number.to_s
    )
  end

  def list
    @ofx_client.list
  end

end
