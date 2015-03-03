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
			devices = Device.where({user_id: filter.user_id, enabled: true})
			puts "Found #{adverts.size} adverts for filter #{filter.id}"

			adverts_count = adverts.size
			if adverts_count > 0
				if devices.size == 0
					puts "Devices for filter #{filter.id} not found or not active"
				else
					puts adverts.first.id
					puts "Sending notofication to user #{filter.user_id}"

					first_advert = adverts.first
					first_advert_mark = first_advert.car_mark
					first_advert_model = first_advert.car_model

					data = {}
					data[:advert_id] = first_advert.id
					data[:car_mark_name] = first_advert_mark.name if first_advert_mark
					data[:car_model_name] = first_advert_model.name if first_advert_model
					data[:price] = first_advert.price
					data[:type] = "new_advert"

					devices.each { |device| NotificationSender.send(device.platform, device.token, { data: data }) }
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