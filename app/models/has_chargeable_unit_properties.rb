# For more on this pattern, visit http://mediumexposure.com/multiple-table-inheritance-active-record/
module HasChargeableUnitProperties
  def self.included(base)
    # Makes it so that any object (base) that includes HasDimensions automatically has a relationship with a DimensionSet object
    base.has_one :chargeable_unit_properties, :as => :chargeable_unit, :autosave => true
    # Any DimensionSet validation must show up in the object that includes HasDimensions
    base.validate :chargeable_unit_properties_must_be_valid
    # Makes it so that whenever anyone accesses dimension set by calling dimension_set the dimension_set_with_autobuild method is called
    base.alias_method_chain :chargeable_unit_properties, :autobuild
    # Add a method to the base and call it.
    base.extend ClassMethods
    base.define_chargeable_unit_properties_accessors
  end

  # Makes it so that when anyone calls dimension_set on an object that includes HasDimensions the DimensionSet will be built automatically
  def chargeable_unit_properties_with_autobuild
    chargeable_unit_properties_without_autobuild || build_chargeable_unit_properties
  end
  
  # Make it so that any time a method is called on an object that includes HasDimensions, if that method exists on the associated DimensionSet object,
  # then that's the method that's going to be sent; otherwise, the method is sent to the object whose class includes HasDimensions.
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : chargeable_unit_properties.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end
  
  def read_attribute(attribute)
    if ChargeableUnitProperties.content_columns.map(&:name).include?(attribute.to_s)
      chargeable_unit_properties.read_attribute(attribute)
    else
      super
    end
  end
  
  def write_attribute(attribute, value)
    # check to see whether we have an accessor for this
    if ChargeableUnitProperties.content_columns.map(&:name).include?(attribute.to_s)
      chargeable_unit_properties.write_attribute(attribute, value)
    else
      super
    end
  end
  
  # This module exists to add methods to the base class that includes has_dimensions
  module ClassMethods
    # This method creates explicit methods for things like height=, so they can be set in initializers and things.
    def define_chargeable_unit_properties_accessors
      # Grab all content columns (rails excludes certain ones like id)
      all_attributes = ChargeableUnitProperties.content_columns.map(&:name)
      # There are a few more that cannot be set by initializers and the like
      ignored_attributes = ["created_at", "updated_at", "measured_object_type"]
      attributes_to_delegate = all_attributes - ignored_attributes
      # create methods for these attributes on the base object
      attributes_to_delegate.each do |attrib|
        class_eval <<-RUBY
          def #{attrib}
            chargeable_unit_properties.#{attrib}
          end

          def #{attrib}=(value)
            self.chargeable_unit_properties.#{attrib} = value
          end

          def #{attrib}?
            self.chargeable_unit_properties.#{attrib}?
          end
        RUBY
      end
    end
  end

  def cubic_feet
    if self.length.nil? || self.width.nil? || self.height.nil?
      return nil
    else
      divisor = Rails.application.config.box_dimension_divisor
      return (self.length/divisor) * (self.width/divisor) * (self.height/divisor)
    end
  end
  
  protected
    def chargeable_unit_properties_must_be_valid
      unless chargeable_unit_properties.valid?
        chargeable_unit_properties.errors.each do |attr, message|
          errors.add(attr, message)
        end
      end
    end
end