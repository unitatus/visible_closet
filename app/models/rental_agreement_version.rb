# == Schema Information
# Schema version: 20110730190531
#
# Table name: rental_agreement_versions
#
#  id             :integer         not null, primary key
#  agreement_text :text
#  created_at     :datetime
#  updated_at     :datetime
#

class RentalAgreementVersion < ActiveRecord::Base
end
