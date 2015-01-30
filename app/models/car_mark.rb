class CarMark < ActiveRecord::Base
	validates :name, presence: true, uniqueness: {case_sensitive: false}

	def self.find_or_create_by_name(name)
		existed = CarMark.where("lower(name) = :name", {name: name.mb_chars.downcase.to_s}).first

		if existed.nil?
			existed = CarMark.create({name: name})
		end

		existed
	end
end
