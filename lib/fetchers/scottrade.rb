# Disable the autogen version, because Scottrade does not take an account number.
# Providing one at fetch-time leads to an OK response, but with no data returned.
BankJob.disabled << "Invest::AutogenScottradeInc"

class BankJob::Invest::Scottrade < BankJob::Fetcher
  URL = "https://ofxstl.scottsave.com"

  needs :username, "This should also be your account number."
  needs :password

  institution "Scottrade"
  ofx_fid 777

  def initialize(args)
    super

    @ofx_client = BankJob::OfxClient.new(
      :user     => username,
      :pass     => password,
      :fiorg    => self.class.institution,
      :fid      => self.class.ofx_fid,
      :url      => URL,
      :brokerid => "www.scottrade.com"
    )
  end

  def fetch
    @ofx_client.fetch(
      :type  => :invest,
      :start => 90.days.ago,
      :acct  => username
    )
  end

  def list
    @ofx_client.list
  end

end
