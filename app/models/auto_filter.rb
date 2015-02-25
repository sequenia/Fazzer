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
			device = Device.where({user_id: filter.user_id}).first
			puts "Found #{adverts.size} adverts for filter #{filter.id}"

			adverts_count = adverts.size
			if adverts_count > 0
				if device.nil?
					puts "Can not find device for filter #{filter.id}"
				else
					puts adverts.first.id
					puts "Sending notofication to device #{device.id} of user #{filter.user_id}"
					NotificationSender.send(device.platform, device.token, {
						data: {
							message: adverts_count == 1 ? "Новое объявление" : "Новых объявлений: #{adverts_count}",
							advert_id: adverts.first.id
						}
					})
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