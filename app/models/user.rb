class User < ActiveRecord::Base
  devise :database_authenticatable,
         :registerable,
         # :recoverable,
         :rememberable,
         # :trackable,
         :validatable

  # attr_accessible :phone
end
