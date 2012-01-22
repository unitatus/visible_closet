# == Schema Information
# Schema version: 20120122055753
#
# Table name: offer_benefits
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  offer_id   :integer
#

class FreeStorageOfferBenefit < OfferBenefit
  has_one :free_storage_benefit_properties, :autosave => true, :dependent => :destroy
  belongs_to :offer
  
  validate :free_storage_benefit_properties_must_be_valid
  
  def new(attrs=nil)
    return_this = super(attrs)
    define_free_storage_benefit_properties_accessors
    return return_this
  end

  def free_storage_benefit_properties_with_autobuild
    free_storage_benefit_properties_without_autobuild || build_free_storage_benefit_properties
  end

  alias_method_chain :free_storage_benefit_properties, :autobuild
  
  def inspect_with_properties
    inspect_without_properties + free_storage_benefit_properties.inspect
  end
  
  alias_method_chain :inspect, :properties
  
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : free_storage_benefit_properties.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end


  protected
    def free_storage_benefit_properties_must_be_valid
      unless free_storage_benefit_properties.valid?
        free_storage_benefit_properties.errors.each do |attr, message|
          errors.add(attr, message)
        end
      end
    end
    
    def define_free_storage_benefit_properties_accessors
      all_attributes = FreeStorageBenefitProperties.content_columns.map(&:name)
      ignored_attributes = ["created_at", "updated_at"]
      attributes_to_delegate = all_attributes - ignored_attributes
      attributes_to_delegate.each do |attrib|
        class_eval <<-RUBY
          def #{attrib}
            free_storage_benefit_properties.#{attrib}
          end

          def #{attrib}=(value)
            self.free_storage_benefit_properties.#{attrib} = value
          end

          def #{attrib}?
            self.free_storage_benefit_properties.#{attrib}?
          end
        RUBY
      end
    end
end
