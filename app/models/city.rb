class City < ActiveRecord::Base
	validates :name, presence: true, uniqueness: {case_sensitive: false}
end
