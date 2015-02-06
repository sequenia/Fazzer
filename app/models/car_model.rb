class CarModel < ActiveRecord::Base
	validates :name, presence: true

	belongs_to :car_mark

	after_create :update_version
	after_update :update_version
	after_destroy :update_version

	def self.find_or_create_by_name_and_mark(name, mark_id)
		existed = CarModel.where("lower(name) = :name AND car_mark_id = :car_mark_id",
			{name: name.mb_chars.downcase.to_s, car_mark_id: mark_id}).first

		if existed.nil?
			existed = CarModel.create({name: name, car_mark_id: mark_id})
		end

		existed
	end

	private

		def update_version
			versions = Version.first_or_create
			versions.car_models = versions.car_models + 1
			versions.save
		end
end
