# Класс AutoParser ищет на сайте drom.ru новые объявления,
# и заносит ссылки на них в таблицу new_auto_adverts.
# Далее, объявления из этой таблицы парсятся классом AutoAdvertParser.
#
# Парсинг происходит по регионам. Периодическая операция запускает метод
# parse_next_region, который ищет в соответствующем регионе новые объявления.

require 'auto_advert_parser.rb'

class AutoParser < DromParser
	@@adverts_table_selector = "div.tab1 table tr" # Строки таблицы с объявлениями
	@@pager_selector = "div.pager"
	@@td_selector = "td"
	@@a_selector = "a"
	@@href_attribute_selector = "href"
	@@advert_id_attribute = "data-bull-id"
	@@class_attribute = "class"
	@@img_selector = "img"
	@@pinned_attribute = "data-is-sticky"
	@@upped_attribute = "data-is-up"
	@@src_attribute = "src"

	attr_accessor :adverts_count

	# Порядок колонок в таблице объявлений
	@@adverts_table_columns = {
		date: 0,
		photo: 1,
		model: 2,
		year: 3,
		engine: 4,
		mileage: 5,
		price: 6
	}

	# Типы объявлений: стандартное, прикрепленное, поднятое.
	# Прикрепленные объявления всегда идут первыми в таблице, не зависимо от времени добавления
	@@advert_types = {
		default: "default",
		pinned: "pinned",
		upped: "upped"
	}

	def initialize
		self.adverts_count = 0
	end

	# Запускает парсинг для следующего по счету региона, если парсинг не запущен
	def parse_next_region
		# Начинаем парсить только если предыдущий парсинг завершился
		if !parsing_is_in_progress
			ParserMessenger.say_about_parsing_start

			region = get_next_region # Достаем из БД следующий регион
			if region
				begin
					# Заносим в БД информацию о начале парсинга
					result = ParsingResult.create({
						result_type: "regions",
						is_parsing: true,
						success: false,
						region_id: region.id
					})

					# Ищем на сайте новые объявления и сохраняем их
					save_region_adverts(region.href)

					# После парсинга записываем в бд, что он завершился с успехом
					result.update_attributes({success: true, info: "Region #{region.id} parsed with #{self.adverts_count} new adverts"})
				rescue Exception => e
					result.update_attributes({success: false, info: e.message}) if result
					puts e.message
					puts e.backtrace.inspect
				ensure
					# В любом случае сообщаем о том, что парсинг завершился
					result.update_attributes({is_parsing: false}) if result
				end
			else
				ParserMessenger.say_about_no_next_region
			end
		end
	end

	# Сохраняет в БД ссылки на новые объявления с региона за последние 2 дня.
	def save_region_adverts(region_href)
		ParserMessenger.say_about_region_parsing(region_href)

		page_index = 1       # Номер текущей страницы с объявлениями
		session = new_session

		DromParser.set_region(session) # Задаем регион для корректного отображения объявлений

		# Парсим страницы с объявлениями, пока не преодолеем лимит по дате или по страницам
		while page_index <= 100
			sleep 2
			page_href = region_href + "page#{page_index}"
			ParserMessenger.say_about_page_loading(page_href)

			if DromParser.visit_page(session, page_href)
				ParserMessenger.say_loaded(page_href)
				page = Nokogiri::HTML.parse(session.html)
				# Если преодолели лимит по дате или нельзя показать следующую страницу, заканчиваем
				break if !(save_adverts_table(page, region_href) && can_show_next_page(page, page_href))
			end

			page_index += 1
		end

		session.driver.quit

		ParserMessenger.say_about_region_parsing_end(region_href)
	end


	# Сохраняет ссылки на новые объявления в таблицу new_auto_adverts
	# Если преодолен лимит по дате, возвращает false.
	def save_adverts_table(adverts_page, region_href)
		adverts = adverts_page.css(@@adverts_table_selector)
		adverts.drop(1).each do |advert|
			columns = advert.css(@@td_selector)

			code = advert.attribute(@@advert_id_attribute).value
			date = columns[@@adverts_table_columns[:date]].text
			url = columns[@@adverts_table_columns[:date]].css(@@a_selector).first[@@href_attribute_selector]
			model = DromParser.strip(columns[@@adverts_table_columns[:model]].text, " \n")
			type = get_advert_type(advert)

			photo = columns[@@adverts_table_columns[:photo]].at_css(@@img_selector)
			photo_preview_url = photo.attribute(@@src_attribute).value if photo

			if needs_stop(date)
				puts "Date limit succeed! #{date}"
				return false
			end

			if AutoAdvert.exists?({code: code}) || NewAutoAdvert.exists?({code: code})
				ParserMessenger.say_about_existed_advert(code)
			else
				NewAutoAdvert.create({
					url: url,
					code: code,
					photo_preview_url: photo_preview_url,
					region_href: region_href
				})
				self.adverts_count = self.adverts_count + 1
			end
		end

		return true
	end

	protected

		def can_show_next_page(page, page_href)
			if page.at_css(@@pager_selector).nil?
				ParserMessenger.say_about_pager_missing(page_href)
				return false
			end

			return true
		end

		# default, pinned, upped
		def get_advert_type(advert_row)
			upped = advert_row.attribute(@@upped_attribute)
			pinned = advert_row.attribute(@@pinned_attribute)

			if pinned && pinned.value.to_i > 0
				return @@advert_types[:pinned]
			elsif upped && upped.value.to_i > 0
				return @@advert_types[:upped]
			end

			return @@advert_types[:default]
		end

		# Возвращает true, если парсинг уже запущен
		def parsing_is_in_progress
			last_parsing = ParsingResult.where({result_type: ParsingResult.result_types[:regions]}).last
			if last_parsing
				last_parsing.is_parsing
			else
				false
			end
		end

		# Ищет следующий регион после предыдущего парсинга
		def get_next_region
			last_region = get_last_region
			if last_region
				Region.where("id > :last_region_id", {
					last_region_id: last_region.id
				}).order("id ASC").first || Region.first
			else
				Region.first
			end
		end

		# Возвращает регион последнего парсинга
		def get_last_region
			last_parsing = ParsingResult.where({result_type: ParsingResult.result_types[:regions]}).last
			last_parsing.region if last_parsing
		end

		def date_difference_in_days(d1, d2)
			# Разность в секундах / (60 * 60 * 24)
			(d1.to_f - d2.to_f) / 86400.0
		end

		def needs_stop(date)
			now = DateTime.now

			day, month = date.split("-")
			day = day.to_i
			month = month.to_i
			year = (month > now.month) ? now.year - 1 : now.year

			advert_date = DateTime.new(year, month, day, 0, 0, 0)

			date_difference_in_days(now, advert_date) >= 2
		end
end