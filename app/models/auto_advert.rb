class AutoAdvert < ActiveRecord::Base
	belongs_to :city
	belongs_to :car_mark
	belongs_to :car_model

	enum fuel: [:gasoline, :diesel]
	enum steering_wheel: [:right, :left]
	enum drive: [:full, :front, :rear]
	enum transmission: [:manual, :automatic]
	enum body: [:sedan, :jeep, :hatchback, :estate, :van, :coupe, :open, :pickup]

	def self.get_min_info
		self.select("auto_adverts.id, auto_adverts.year, auto_adverts.price,\
			auto_adverts.car_mark_id, car_marks.name AS car_mark_name, \
			auto_adverts.car_model_id, car_models.name AS car_model_name")
		.joins("LEFT OUTER JOIN car_marks \
						ON car_marks.id = auto_adverts.car_mark_id")
		.joins("LEFT OUTER JOIN car_models \
						ON car_models.id = auto_adverts.car_model_id")
		.limit(5)
		.order("auto_adverts.id DESC")
	end

	def self.all_new
		self.where({is_new: true})
	end

	def self.create_from_info(info)
		return nil if info.nil?
		return nil if info[:code].nil?

		params = {
			code: info[:code],
			date: info[:date],
			year: info[:year],
			price: info[:price],
			phone: (info[:phones] || []).join(", "),
			fuel: self.convert_fuel(info[:fuel]),
			displacement: info[:displacement],
			transmission: self.convert_transmission(info["Трансмиссия:"]),
			drive: self.convert_drive(info["Привод:"]),
			mileage: info["Пробег, км:"],
			steering_wheel: self.convert_steering_wheel(info["Руль:"]),
			description: info["Дополнительно:"],
			exchange: info["Обмен:"],
			color: info["Цвет:"],
			body: self.convert_body(info["Тип кузова:"]),
			url: info[:url]
		}

		if info[:mark]
			car_mark = CarMark.find_or_create_by({name: info[:mark]})
			params[:car_mark_id] = car_mark.id

			if info[:model]
				car_model = CarModel.find_or_create_by({
					name: info[:model],
					car_mark_id: car_mark.id
				})
				params[:car_model_id] = car_model.id
			end
		end

		if info["Город:"]
			city = City.find_or_create_by({name: info["Город:"]})
			params[:city_id] = city.id
		end

		self.create(params)
	end

	private

		def self.convert_fuel(text)
			return nil if text.nil?

			value = text.downcase

			if value == "бензин"
				"gasoline"
			elsif value == "дизель"
				"diesel"
			end
		end

		def self.convert_steering_wheel(text)
			return nil if text.nil?

			value = text.downcase

			if value == "левый"
				"left"
			elsif value == "правый"
				"right"
			end
		end

		def self.convert_drive(text)
			return nil if text.nil?

			value = text.downcase

			if value == "передний"
				"front"
			elsif value == "задний"
				"rear"
			elsif value == "4wd"
				"full"
			end
		end

		def self.convert_transmission(text)
			return nil if text.nil?

			value = text.downcase

			if value == "механика"
				"manual"
			elsif value == "автомат"
				"automatic"
			end
		end

		def self.convert_body(text)
			return nil if text.nil?

			value = text.downcase

			if value == "седан"
				"sedan"
			elsif value == "джип (suv)"
				"jeep"
			elsif value == "хэтчбек"
				"hatchback"
			elsif value == "универсал"
				"estate"
			elsif value == "минивэн / микроавтобус"
				"van"
			elsif value == "купе"
				"coupe"
			elsif value == "открытый"
				"open"
			elsif value == "пикап"
				"pickup"
			end
		end
end
