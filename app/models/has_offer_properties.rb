# For more on this pattern, visit http://mediumexposure.com/multiple-table-inheritance-active-record/, or see the HasChargeableUnitProperties class
module HasOfferProperties
  def self.included(base)
    base.has_one :offer_properties, :as => :offer, :autosave => true, :dependent => :destroy
    base.validate :offer_properties_must_be_valid
    base.alias_method_chain :offer_properties, :autobuild
    base.alias_method_chain :inspect, :properties
    base.extend ClassMethods
    base.define_offer_properties_accessors
  end

  def offer_properties_with_autobuild
    offer_properties_without_autobuild || build_offer_properties
  end
  
  def inspect_with_properties
    inspect_without_properties + offer_properties.inspect
  end
  
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : offer_properties.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end
  
  module ClassMethods
    def define_offer_properties_accessors
      all_attributes = OfferProperties.content_columns.map(&:name)
      ignored_attributes = Array.new # ["created_at", "updated_at", "measured_object_type"]
      attributes_to_delegate = all_attributes - ignored_attributes
      attributes_to_delegate.each do |attrib|
        class_eval <<-RUBY
          def #{attrib}
            offer_properties.#{attrib}
          end

          def #{attrib}=(value)
            self.offer_properties.#{attrib} = value
          end

          def #{attrib}?
            self.offer_properties.#{attrib}?
          end
        RUBY
      end
    end
  end

  protected
    def offer_properties_must_be_valid
      unless offer_properties.valid?
        offer_properties.errors.each do |attr, message|
          errors.add(attr, message)
        end
      end
    end
end