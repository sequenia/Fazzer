class AutoAdvert < ActiveRecord::Base

	FUEL_TYPES = {
		:gasoline => "Бензин",
		:diesel => "Дизель"
	}

	def fuel
		value = read_attribute(:fuel)
		if value
			value.to_sym
		end
	end

	def fuel= (value)
		write_attribute(:fuel, value.nil? ? value : value.to_s)
	end

	def self.fuel_types
		FUEL_TYPES
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
			transmission: info["Трансмиссия:"],
			drive: info["Привод:"],
			mileage: info["Пробег, км:"],
			steering_wheel: info["Руль:"],
			description: info["Дополнительно:"],
			exchange: info[:exchange],
			color: info["Цвет:"],
			body: info["Тип кузова:"]
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

		def self.convert_fuel(fuel)
			return nil if fuel.nil?

			value = fuel.downcase

			if value == "бензин"
				:gasoline
			elsif value == "дизель"
				:diesel
			end
		end
end
