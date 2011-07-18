# == Schema Information
# Schema version: 20110717194124
#
# Table name: users
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  reset_password_token :string(255)
#  remember_created_at  :datetime
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  password_salt        :string(255)
#  confirmation_token   :string(255)
#  confirmed_at         :datetime
#  confirmation_sent_at :datetime
#  failed_attempts      :integer         default(0)
#  unlock_token         :string(255)
#  locked_at            :datetime
#  authentication_token :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  last_name            :string(255)
#  first_name           :string(255)
#  beta_user            :boolean         default(TRUE)
#  signup_comments      :text
#  role                 :string(255)
#

class User < ActiveRecord::Base
  # Roles
  ADMIN = :admin
  MANAGER = :manager
  NORMAL = :normal

  # Other devise modules are:
  # :token_authenticatable, :encryptable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :lockable, :timeoutable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, 
                  :password, # not stored in DB
                  :password_confirmation, # not stored in DB
                  :remember_me, 
                  :beta_user,
                  :first_name,
                  :last_name,
                  :signup_comments,
                  :role

  symbolize :role

  has_many :boxes

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates_inclusion_of :role, :in => [ ADMIN, MANAGER, NORMAL ]

  has_many :addresses
    
  def after_initialize 
    self.role ||= NORMAL
  end
end
