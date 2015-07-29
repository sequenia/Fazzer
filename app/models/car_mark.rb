class CarMark < ActiveRecord::Base
	validates :name, presence: true, uniqueness: {case_sensitive: false}

	after_create :update_version
	after_update :update_version
	after_destroy :update_version

	has_many :car_models

	def self.find_or_create_by_name(name)
		existed = CarMark.where("lower(name) = :name", {name: name.mb_chars.downcase.to_s}).first

		if existed.nil?
			existed = CarMark.create({name: name})
		end

		existed
	end

	private

		def update_version
			versions = Version.first_or_create
			versions.car_marks = versions.car_marks + 1
			versions.save
		end
end
