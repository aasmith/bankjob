require File.join(File.dirname(__FILE__), '../lib/bankjob')

class BankJob::Bank::FooBank < BankJob::Fetcher
  needs :username, "Eight-character username provided by your bank."
  needs :password

  institution "Example Bank, NA."
  description "Provides access to MyExample accounts"

  ofx_fid 1042

  def fetch
    puts "Fetching #{self.class}"
  end
end

class BankJob::Cc::BarBank < BankJob::Fetcher
  institution "Bar Bank"
  description "Bar Bank for accounts in WA."

  needs :username
  needs :password
  needs :last_4_ssn, "The last 4 digits of your social security number."
end

class BankJobTest < Test::Unit::TestCase
  def test_classes_extending_fetcher_are_registered
    assert BankJob::Fetcher.fetchers.all?{|c| c.ancestors.include?(BankJob::Fetcher)}
  end

  def test_params_in_new_fetcher_are_accessible_if_in_needs
    bank = BankJob::Bank::FooBank.new(:foo => 1, :username => "bob")
    assert_raises(NoMethodError, "never needed") { bank.foo }
    assert_raises(NoMethodError, "not in the args to new") { bank.password }
    assert_equal "bob", bank.username

    other_bank = BankJob::Cc::BarBank.new(:foo => "hello", :username => "alice")
    assert_raises(NoMethodError) { other_bank.foo }
    assert_equal "alice", other_bank.username
  end

  def test_finds_fetcher
    assert_equal BankJob::Cc::BarBank, BankJob::Fetcher.find(:institution => "Bar Bank")
  end

  def test_find_fetcher_mutliple_params
    assert_equal BankJob::Bank::FooBank, BankJob::Fetcher.find(
      :institution => BankJob::Bank::FooBank.institution,
      :description => BankJob::Bank::FooBank.description
    )
    
    assert_nil BankJob::Fetcher.find(
      :institution => BankJob::Cc::BarBank.institution, 
      :description => BankJob::Bank::FooBank.description
    )
  end

  def test_find_doesnt_error_on_missing_methods
    assert_nothing_raised do
      assert_nil BankJob::Fetcher.find(:wobbly => true)
    end
  end

  def test_type_is_based_on_module
    [:cc, :bank, :invest].each do |t|
      class_name = t.to_s.capitalize
      assert BankJob.const_defined?(class_name), "#{t} should be defined"
      klass = BankJob.const_get(class_name)
      assert_equal BankJob, klass.parent
    end

    BankJob::Fetcher.fetchers.each do |f|
      assert [:cc, :bank, :invest].include?(f.institution_type),
        "#{f} should be defined in the BankJob::{Cc,Bank,Invest} namespace"
    end
  end
end
