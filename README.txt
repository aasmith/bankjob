= bankjob

 * http://github.com/aasmith/bankjob

== DESCRIPTION:

Bankjob fetches financial data from your bank or other financial institution.

== SYNOPSIS:

 require 'bankjob'

 # find a fetcher for your bank:
 fetcher_class = BankJob::Fetcher.find(:institution=>"US Bank")
 # => BankJob::Bank::UsBank

 # find out what it needs (with optional descriptions)
 fetcher_class.needs
 # => [[:username], [:password], [:account_number, "Your 9 digit account number"]]

 # set up an instance
 fetcher = fetcher_class.new(
   :username       => "exampleusername",
   :password       => "examplesecret",
   :account_number => 123456
 )

 # do a bankjob, get lots of OFX.
 fetcher.fetch
 # => "OFXHEADER:100\r\nDATA:OFXS ... RS></BANKMSGSRSV1></OFX>"


=== A more detailed example

 (may require gem install ofx-parser)

 require 'rubygems'
 require 'ofx-parser'
 require 'bankjob'

 credentials = {:username => "abc", :password => "123"}

 fetcher = BankJob::Cc::AutogenCitiCards.new(credentials)

 # Get a list of accounts for this user, as the account number may be
 # something the user doesn't know, or maybe the remote system uses a
 # different reference or a specific formatting.

 list_response = fetcher.list 
 # => "OFXHEADER:100\nDAT..etc..<ACCTID>XXXXXXXXXXXX9324..etc..PMSGSRSV1>\n</OFX>\n"

 # at this point, parse out the account number above. I'll use ofx-parser.
 list_doc = OfxParser::OfxParser.parse(list_response)
 # => #<OfxParser::Ofx:0x2aaaad65ebe0>

 account_number = list_doc.signup_account_info.first.number
 # => "XXXXXXXXXXXX9324"

 # get a new fetcher with more details to provide.
 fetcher = BankJob::Cc::AutogenCitiCards.new(
             credentials.merge(:account_number => account_number)))

 # Get all the transaction details for the newly-found account.
 fetch_reponse = fetcher.fetch
 # => "OFXHEADER:100\nDAT..etc..DITCARDMSGSRSV1>\n</OFX>\n""

 # Do what you want. The rest of this is just an ofx parser example.
 ofx_doc = OfxParser::OfxParser.parse(fetch_reponse)

 transaction = ofx_doc.credit_card.statement.transactions.last
 transaction.sic_desc
 # => "MISCELLANEOUS GENERAL MERCHANDISE STORES"
 transaction.amount_in_pennies
 # => -543

=== Finding a fetcher

 # Find the first fetcher that matches given parameters.
 BankJob::Fetcher.find(:institution => "Citi Cards", :institution_type => :cc)

 # Or use Enumrable methods to find more.
 BankJob::Fetcher.fetchers.select{|f|f.institution_type == :cc}

== INSTALL:

 * sudo gem install bankjob

== NOTES:

All banks that provide a native OFX source should be supported. Other banks
that do not provide this service can be added using screen-scraping or
other methods. An example of this is the US Bank fetcher in lib/fetchers.

Many banks were added from an auto generated source. Not all of these have
been tested, and your feedback is appreciated. The following auto generated
OFX fetchers are known to work:

 BankJob::Cc::AutogenDiscoverCard
 BankJob::Cc::AutogenChase
 BankJob::Cc::AutogenCitiCards

== LICENSE:

Copyright (c) 2008 Andrew A. Smith

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
