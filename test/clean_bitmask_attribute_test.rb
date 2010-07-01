require 'clean_test_helper'

class CleanBitmaskAttributeTest < Test::Unit::TestCase
  
  context "CleanCampaign" do

    should "can assign single value to bitmask" do
      assert_stored CleanCampaign.new(:medium => :web), :web
    end

    should "can assign multiple values to bitmask" do
      assert_stored CleanCampaign.new(:medium => [:web, :print]), :web, :print
    end

    should "can add single value to bitmask" do
      campaign = CleanCampaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
    end

    should "ignores duplicate values added to bitmask" do
      campaign = CleanCampaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
      assert_equal 1, campaign.medium.select { |value| value == :phone }.size
    end

    should "can assign new values at once to bitmask" do
      campaign = CleanCampaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium = [:phone, :email]
      assert_stored campaign, :phone, :email
    end

    should "can add custom behavor to value proxies during bitmask definition" do
      campaign = CleanCampaign.new(:medium => [:web, :print])
      assert_raises NoMethodError do
        campaign.medium.worked?
      end
      assert_nothing_raised do
        campaign.misc.worked?
      end
      assert campaign.misc.worked?
    end

    should "cannot use unsupported values" do
      assert_unsupported { CleanCampaign.new(:medium => [:web, :print, :this_will_fail]) }
      campaign = CleanCampaign.new(:medium => :web)
      assert_unsupported { campaign.medium << :this_will_fail_also }
      assert_unsupported { campaign.medium = [:so_will_this] }
    end

    should "can determine bitmasks using convenience method" do
      assert CleanCampaign.bitmask_for_medium(:web, :print)
      assert_equal(
        CleanCampaign.bitmasks[:medium][:web] | CleanCampaign.bitmasks[:medium][:print],
        CleanCampaign.bitmask_for_medium(:web, :print)
      )
    end
    
    should "assert use of unknown value in convenience method will result in exception" do
      assert_unsupported { CleanCampaign.bitmask_for_medium(:web, :and_this_isnt_valid)  }
    end

    should "hash of values is with indifferent access" do
      string_bit = nil
      assert_nothing_raised do
        assert (string_bit = CleanCampaign.bitmask_for_medium('web', 'print'))
      end
      assert_equal CleanCampaign.bitmask_for_medium(:web, :print), string_bit
    end

    should "save bitmask with non-standard attribute names" do
      campaign = CleanCampaign.new(:Legacy => [:upper, :case])
      assert_equal [:upper, :case], campaign.Legacy
    end

    should "ignore blanks fed as values" do
      campaign = CleanCampaign.new(:medium => [:web, :print, ''])
      assert_stored campaign, :web, :print
    end
    
    should "convert values passed as strings to symbols" do
      campaign = CleanCampaign.new
      campaign.medium << "web"
      assert_equal [:web], campaign.medium
      assert_equal true, campaign.medium?("web")
    end
        
    context "checking" do

      setup { @campaign = CleanCampaign.new(:medium => [:web, :print]) }

      context "for a single value" do
      
        should "be supported by an attribute_for_value convenience method" do
          assert @campaign.medium_for_web?
          assert @campaign.medium_for_print?
          assert !@campaign.medium_for_email?
        end
        
        should "be supported by the simple predicate method" do
          assert @campaign.medium?(:web)
          assert @campaign.medium?(:print)
          assert !@campaign.medium?(:email)
        end

      end
      
      context "for multiple values" do
        
        should "be supported by the simple predicate method" do
          assert @campaign.medium?(:web, :print)
          assert !@campaign.medium?(:web, :email)
        end

      end

    end

    should "can check if at least one value is set" do
      campaign = CleanCampaign.new(:medium => [:web, :print])
      
      assert campaign.medium?
      
      campaign = CleanCampaign.new
      
      assert !campaign.medium?
    end

    #######
    private
    #######

    def assert_unsupported(&block)
      assert_raises(ArgumentError, &block)
    end

    def assert_stored(record, *values)
      values.each do |value|
        assert record.medium.any? { |v| v.to_s == value.to_s }, "Values #{record.medium.inspect} does not include #{value.inspect}"
      end
      full_mask = values.inject(0) do |mask, value|
        mask | CleanCampaign.bitmasks[:medium][value]
      end
      assert_equal full_mask, record.medium.to_i
    end

  end

end
