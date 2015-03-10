# Модель объявлений.
# В таблице хранятся объявления о продаже машин.
class AutoAdvert < ActiveRecord::Base
	belongs_to :city
	belongs_to :car_mark
	belongs_to :car_model

	enum fuel: [:gasoline, :diesel]
	enum steering_wheel: [:right, :left]
	enum drive: [:full, :front, :rear]
	enum transmission: [:manual, :automatic]
	enum body: [:sedan, :jeep, :hatchback, :estate, :van, :coupe, :open, :pickup]

	# Возвращает минимальную информацию об объявлениях
	def self.get_min_info
		self.select_with_fields([:id, :year, :price,
			:car_mark_id, :car_model_id,
			:car_mark_name, :car_model_name, :photo_preview_url])
		.order("auto_adverts.id DESC")
	end

	def self.get_full_info
		self.select_with_fields(AutoAdvert.columns.collect{ |c| c.name }
			.concat([:car_mark_name, :car_model_name, :city_name]))
	end

	# Создает запрос where по переданному фильтру
	def self.filter(f)
		f ||= {}
		where_strings = []
		where_params = {}

		if f[:city_id]
			where_strings << "auto_adverts.city_id = :city_id"
			where_params[:city_id] = f[:city_id]
		end

		if f[:car_mark_id]
			where_strings << "auto_adverts.car_mark_id = :car_mark_id"
			where_params[:car_mark_id] = f[:car_mark_id]
		end

		if f[:car_model_id]
			where_strings << "auto_adverts.car_model_id = :car_model_id"
			where_params[:car_model_id] = f[:car_model_id]
		end

		if f[:min_year]
			where_strings << "year >= :min_year"
			where_params[:min_year] = f[:min_year]
		end

		if f[:max_year]
			where_strings << "year <= :max_year"
			where_params[:max_year] = f[:max_year]
		end

		if f[:min_price]
			where_strings << "price >= :min_price"
			where_params[:min_price] = f[:min_price]
		end

		if f[:max_price]
			where_strings << "price <= :max_price"
			where_params[:max_price] = f[:max_price]
		end

		self.where(where_strings.join(" AND "), where_params)
	end

	# Возвращает запрос к БД с указанными полями.
	# Если полей не указано, возвращается all
	def self.select_with_fields(fields)
		query = nil
		select_strings = []
		joins_strings = []

		if fields.class == Array
			# Генерируем части запроса для полей и джоинов
			fields.each do |field|
				field_name = field.to_s
				if field_name == "car_model_name"
					select_strings << "car_models.name AS car_model_name"
					joins_strings << "LEFT OUTER JOIN car_models ON car_models.id = auto_adverts.car_model_id"
				elsif field_name == "car_mark_name"
					select_strings << "car_marks.name AS car_mark_name"
					joins_strings << "LEFT OUTER JOIN car_marks ON car_marks.id = auto_adverts.car_mark_id"
				elsif field_name == "city_name"
					select_strings << "cities.name AS city_name"
					joins_strings << "LEFT OUTER JOIN cities ON cities.id = auto_adverts.city_id"
				else
					select_strings << "auto_adverts.#{field_name}"
				end
			end
		else
			select_strings << "*"
		end

		query = self.select(select_strings.join(", "))
		joins_strings.each { |j|query = query.joins(j) }

		query
	end

	# Возвращает все новые объявления
	def self.all_new
		self.where({is_new: true})
	end

	# Создает объявление в БД по информации со страницы.
	# Эта информация может включать в себя русские слова и русские ключи.
	def self.create_from_info(info)
		return nil if info.nil?
		return nil if info[:code].nil?

		params = {
			code: info[:code],
			date: info[:date],
			year: info[:year],
			price: info[:price],
			photo_url: info[:photo_url],
			photo_preview_url: info[:photo_preview_url],
			photos_processed: info[:photos_processed],
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

		# Возвращает значение enum для fuel по русскому слову
		def self.convert_fuel(text)
			return nil if text.nil?

			value = text.downcase

			if value == "бензин"
				"gasoline"
			elsif value == "дизель"
				"diesel"
			end
		end

		# Возвращает значение enum для руля по русскому слову
		def self.convert_steering_wheel(text)
			return nil if text.nil?

			value = text.downcase

			if value == "левый"
				"left"
			elsif value == "правый"
				"right"
			end
		end

		# Возвращает значение enum для drive по русскому слову
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

		# Возвращает значение enum для transmission по русскому слову
		def self.convert_transmission(text)
			return nil if text.nil?

			value = text.downcase

			if value == "механика"
				"manual"
			elsif value == "автомат"
				"automatic"
			end
		end

		# Возвращает значение enum для body по русскому слову
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
