class BankJob::Bank::UsBank < BankJob::Fetcher
  USBANK_TZ = "America/Chicago"

  needs :username
  needs :password
  needs :account_number

  institution "US Bank"
  ofx_fid 1402

  def fetch
    a = WWW::Mechanize.new

    p = a.get(
      'https://www4.usbank.com/internetBanking/RequestRouter?requestCmdId=DisplayLoginPage')
    f = p.form_with(:name => 'logon')
    f.USERID = username
    p = f.submit

    f = p.form_with(:name=>'password')
    f.PSWD = password
    p = f.submit

    p = p.links.text("Download Transaction Data").click

    f = p.form_with(:name => 'download')
    accts = f.field('TDACCOUNTLIST')
    accts.options.detect{|o|
      o.text =~ /#{account_number.to_s.last(4)}\s/
    }.click

    fmt = f.field('TDSOFTWARE')
    fmt.options.detect{|o|o.text =~ /Microsoft Money 98 or newer/}.click

    Time.use_zone(USBANK_TZ) do
      f.field('TDENDDATE').value = Time.zone.now.strftime("%Y%m%d")
      f.field('TDLASTDOWNLOADDATE').value = 89.days.ago.strftime("%Y%m%d")
    end

    file = f.submit
    file.body
  end
end

