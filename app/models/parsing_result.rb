# Результаты парсинга.
# В таблице хранятся результаты о различных парсингах (Регионы, объявления и т.д.)
class ParsingResult < ActiveRecord::Base
	belongs_to :region

	enum result_type: [:regions, :adverts]

	def self.regions_results
		self.where({result_type: ParsingResult.result_types[:regions]})
	end

	def self.adverts_results
		self.where({result_type: ParsingResult.result_types[:adverts]})
	end

	def self.last_regions_results
		self.regions_results.order("id DESC").limit(Region.all.size + 1)
	end

	def self.last_adverts_results
		self.adverts_results.order("id DESC").limit(10)
	end

	def get_region
		r = region
		r ? "%d: %s" % [r.id, r.href] : "Нет"
	end

	def self.regions_process_time
		results = self.last_regions_results
		first_date = results.first.created_at
		second_date = results.last.created_at
		(first_date.to_f - second_date.to_f) / 3600
	end

	def self.new_adverts_speed
		NewAutoAdvert.where("created_at <= :now AND created_at >= :ago", {
			now: DateTime.now,
			ago: 1.day.ago
		}).size
	end

	def self.adverts_parsing_speed
		AutoAdvert.where("created_at <= :now AND created_at >= :ago", {
			now: DateTime.now,
			ago: 1.day.ago
		}).size
	end
end
