class AutoFilter < ActiveRecord::Base
	belongs_to :car_mark
	belongs_to :car_model

	def self.check_new_adverts
		puts "Try to find adverts to filters..."
		AutoFilter.where("email IS NOT NULL").each do |filter|
			adverts = filter.find_new_adverts
			puts "Found #{adverts.size} adverts for filter #{filter.id}"

			if adverts.size > 0
				filter_attrs = {
					min_year: filter.min_year,
					max_year: filter.max_year,
					min_price: filter.min_price,
					max_price: filter.max_price,
				}
				car_model = filter.car_model
				car_mark = filter.car_mark
				if car_model
					filter_attrs[:car_model_name] = car_model.name
				end
				if car_mark
					filter_attrs[:car_mark_name] = car_mark.name
				end

				FazzerMailer.new_adverts_message(
					adverts.collect { |advert| { url: advert.url } },
					filter_attrs,
					filter.email
				).deliver_later
			end
		end

		AutoFilter.archive_adverts(AutoAdvert.all_new)
	end

	def self.archive_adverts(adverts)
		adverts.each do |advert|
			advert.update_attributes({is_new: false})
		end
	end

	def find_new_adverts
		where_strings = []
		where_params = {}

		if self.car_mark_id
			where_strings << "car_mark_id = :car_mark_id"
			where_params[:car_mark_id] = self.car_mark_id
		end

		if self.car_model_id
			where_strings << "car_model_id = :car_model_id"
			where_params[:car_model_id] = self.car_model_id
		end

		if self.min_year
			where_strings << "year >= :min_year"
			where_params[:min_year] = self.min_year
		end

		if self.max_year
			where_strings << "year <= :max_year"
			where_params[:max_year] = self.max_year
		end

		if self.min_price
			where_strings << "price >= :min_price"
			where_params[:min_price] = self.min_price
		end

		if self.max_price
			where_strings << "price <= :max_price"
			where_params[:max_price] = self.max_price
		end

		where_strings << "is_new = :is_new"
		where_params[:is_new] = true

		AutoAdvert.where(where_strings.join(" AND "), where_params)
	end
end
