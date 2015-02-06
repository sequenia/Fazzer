class City < ActiveRecord::Base
	validates :name, presence: true, uniqueness: {case_sensitive: false}

	after_create :update_version
	after_update :update_version
	after_destroy :update_version

	private

		def update_version
			versions = Version.first_or_create
			versions.cities = versions.cities + 1
			versions.save
		end
end
