class StoredItemTag < ActiveRecord::Base
  belongs_to :stored_items

  attr_accessible :tag
end