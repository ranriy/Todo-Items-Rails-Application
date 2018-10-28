class User < ActiveRecord::Base
  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :todolists, dependent: :destroy
  has_many :todoitems, through: :todolists, source: :todoitems
end
