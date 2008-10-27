= bankjob

 * http://github.com/aasmith/bankjob

== DESCRIPTION:

Bankjob fetches financial data from your bank or other financial institution.

== SYNOPSIS:

 require 'bankjob'

 # find a fetcher for your bank:
 fetcher_class = BankJob::Fetcher.find(:institution=>"US Bank")
 # => BankJob::UsBank

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


== INSTALL:

 * sudo gem install bankjob

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
