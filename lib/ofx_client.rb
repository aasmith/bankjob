# Based on ofx.py, written in Python by Steve Dunham <dunham@cse.msu.edu>,
# ported to Ruby and modified by Andrew A. Smith.

require 'net/https'

require 'uuid'

class Time
  def ofx
    strftime('%Y%m%d%H%M%S.000')
  end
end

module BankJob
  class OfxClient

    DEFAULTS = {
      :appid => "Money",
      :appver => "1700",
      :start => Time.now - 31*86400
    }

    attr_accessor :opts, :cookie

    # opts user, pass, appid, appver
    # type one of :cc, :invest, :banking
    def initialize(opts)
      @uuid = UUID.new
      @opts = DEFAULTS.merge(opts)
      @cookie = 3
    end

    # :type => :cc/:invest/:bank 
    # :acct => "123456"
    # :start => (Time.now - 31*86400) # 31 days ago
    def fetch(opts)
      @opts.merge!(opts)
      ofx_req = build_query(opts[:type] || @opts[:type])
      do_query(ofx_req)
    end

    def list
      fetch(:type => :acct)
    end

    undef cookie
    def cookie
      @cookie += 1
    end

    def field(tag, value)
      "<#{tag}>#{value}"
    end

    def tag(tag, *contents)
      ["<#{tag}>", contents, "</#{tag}>"].join((contents.size == 1 && contents.first !~ />/) ? "" : "\r\n")
    end

    def uuid
      @uuid.generate
    end

    def sign_on
      fidata = [field("ORG", opts[:fiorg])]
      fidata << field("FID", opts[:fid]) if opts[:fid]

      tag("SIGNONMSGSRQV1",
        tag("SONRQ",
          field("DTCLIENT", Time.now.ofx),
          field("USERID", opts[:user]),
          field("USERPASS", opts[:pass]),
          field("LANGUAGE", "ENG"),
          tag("FI", *fidata),
          field("APPID", opts[:appid]),
          field("APPVER", opts[:appver])
      ))
    end

    def build_query(type)
      [header, tag("OFX", sign_on, send("#{type}_msg"))].join("\r\n")
    end

    def invest_msg
      message("INVSTMT", "INVSTMT",
        tag("INVSTMTRQ",
          tag("INVACCTFROM",
            field("BROKERID", opts[:brokerid] || opts[:fiorg]),
            field("ACCTID", opts[:acct])),
            tag("INCTRAN",
              field("DTSTART", opts[:start].ofx),
              field("INCLUDE","Y")),
            field("INCOO","Y"),
            tag("INCPOS",
              field("DTASOF", Time.now.ofx),
              field("INCLUDE","Y")),
            field("INCBAL","Y")))
    end

    def acct_msg
      message("SIGNUP", "ACCTINFO", 
        tag("ACCTINFORQ", 
          field("DTACCTUP",Time.at(0).utc.ofx)))
    end

    def cc_msg
      message("CREDITCARD", "CCSTMT",
        tag("CCSTMTRQ",
          tag("CCACCTFROM",
            field("ACCTID", opts[:acct])),
          tag("INCTRAN",
            field("DTSTART", opts[:start].ofx),
            field("INCLUDE", "Y"))))
    end

    def banking_msg
      message("BANK", "STMT",
        tag("STMTRQ",
          tag("BANKACCTFROM",
            field("ACCTID", opts[:acct]),
            field("BANKID", "ROUTINGNUMBER-FIXME"),
            field("ACCTTYPE", "CHECKING-SAVINGS-ETC-FIXME")),
          tag("INCTRAN",
            field("DTSTART", opts[:start].ofx),
            field("INCLUDE", "Y"))))
    end

    def message(msg_type, tran_type, req)
      tag(msg_type + "MSGSRQV1",
        tag(tran_type + "TRNRQ",
          field("TRNUID", uuid),
          field("CLTCOOKIE", cookie),
          req))
    end

    def header
      [ "OFXHEADER:100",
        "DATA:OFXSGML",
        "VERSION:102",
        "SECURITY:NONE",
        "ENCODING:USASCII",
        "CHARSET:1252",
        "COMPRESSION:NONE",
        "OLDFILEUID:NONE",
        "NEWFILEUID:#{uuid}",
        ""].join("\r\n")
    end

    def do_query(query)
      url = URI.parse(opts[:url])

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      resp, data = http.post(url.request_uri, query, {
        "Content-type" => "application/x-ofx",
        "Accept" => "*/*",
        "User-Agent" => "MNYINET"
      })

      if $DEBUG
        puts "SENDING " + ("=" * 60)
        puts query
        puts
        puts "GOT " + ("=" * 64)
        puts resp.code, resp.message, data
      end

      data
    end

  end

end
