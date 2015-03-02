class AutoFilter < ActiveRecord::Base
	belongs_to :car_mark
	belongs_to :car_model
	belongs_to :user
	belongs_to :city

	# Для каждого пользовательского фильтра ищет подходящие новые объявления,
	# и производит рассылку о них.
	def self.check_new_adverts
		puts "Try to find adverts to filters..."
		AutoFilter.all.each do |filter|
			adverts = filter.find_new_adverts
			device = Device.where({user_id: filter.user_id, enabled: true}).first
			puts "Found #{adverts.size} adverts for filter #{filter.id}"

			adverts_count = adverts.size
			if adverts_count > 0
				if device.nil?
					puts "Device for filter #{filter.id} not found or not active"
				else
					puts adverts.first.id
					puts "Sending notofication to device #{device.id} of user #{filter.user_id}"

					first_advert = adverts.first
					first_advert_mark = first_advert.car_mark
					first_advert_model = first_advert.car_model

					data = {}
					data[:advert_id] = first_advert.id
					data[:car_mark_name] = first_advert_mark.name if first_advert_mark
					data[:car_model_name] = first_advert_model.name if first_advert_model
					data[:price] = first_advert.price
					data[:type] = "new_advert"

					NotificationSender.send(device.platform, device.token, { data: data })
				end
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
		AutoAdvert.filter(self.attributes_for_advert).all_new.order("id DESC")
	end

	def attributes_for_advert
		attrs = {}
		self.attributes.each do |key, value|
			attrs[key.to_sym] = value
		end
		attrs
	end
end

#if adverts.size > 0
	#filter_attrs = {
	#	min_year: filter.min_year,
	#	max_year: filter.max_year,
	#	min_price: filter.min_price,
	#	max_price: filter.max_price,
	#}
	#filter_car_model = filter.car_model
	#filter_car_mark = filter.car_mark
	#filter_city = filter.city
	#if filter_car_model
	#	filter_attrs[:car_model_name] = filter_car_model.name
	#end
	#if filter_car_mark
	#	filter_attrs[:car_mark_name] = filter_car_mark.name
	#end
	#if filter_city
	#	filter_attrs[:city_name] = filter_city.name
	#end

	#FazzerMailer.new_adverts_message(
	#	adverts.collect { |advert| { url: advert.url } },
	#	filter_attrs,
	#	filter.email
	#).deliver_later
#end