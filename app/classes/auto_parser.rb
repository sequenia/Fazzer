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

	# Запускает парсинг для следующего региона, если парсинг не запущен
	def parse_next_region
		# Начинаем парсить только если предыдущий парсинг завершился
		if !parsing_is_in_progress
			ParserMessenger.say_about_parsing_start

			region = get_next_region
			if region
				begin
					# Пытаемся распарсить регион и заносим информацию об этом в БД
					result = ParsingResult.create({
						region_id: region.id,
						is_parsing: true,
						success: false
					})

					AutoParser.new.save_last_region_adverts(region.href)
					AutoFilter.check_new_adverts

					# После парсинга записываем в бд, что он завершился с успехом
					result.update_attributes({success: true})
				rescue Exception => e
					# Ничего не делаем, ибо success == false по умолчанию
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

	# Сохраняет в БД последние объявления с переданного региона
	def save_last_region_adverts(region_href)
		ParserMessenger.say_about_region_parsing(region_href)

		session = new_session
		DromParser.set_region(session)

		page_index = 1
		while save_adverts_from_page(region_href, page_index, session)
			ParserMessenger.say_about_region_page_parsed(page_index, region_href)
			page_index += 1
		end

		session.driver.quit

		ParserMessenger.say_about_region_parsing_end(region_href)
	end

	# Парсит все объявления со страници и сохраняет их в БД.
	# Возвращает false/nil, если нужно закончить парсинг (Последние объявления закончились),
	# true, если можно продолжать.
	def save_adverts_from_page(region_href, page_index, session)
		sleep 5

		page_href = region_href + "page#{page_index}"

		if DromParser.visit_page(session, page_href)
			page = Nokogiri::HTML.parse(session.html)
			ParserMessenger.say_about_adverts_table_parsing(page_href)
			adverts_table = get_adverts_table(page)
			ParserMessenger.print_adverts_table(adverts_table)

			if adverts_table.size == 0
				ParserMessenger.say_about_no_adverts(page_href)
				return false
			end

			# Продолжаем парсинг только в том случае, если
			# не пройден лимит по дате,
			# есть пагинатор и
			# еще не прошли 100 страниц
			return save_adverts_from_table(adverts_table, page_href) && page_index < 100 && can_show_next_page(page, page_href)
		end
	end

	# Сохраняет в БД объявления из переданной таблицы.
	# Возвращает true, если можно продолжать парсинг.
	# Возвращает false, если парсинг продолжать нельзя.
	def save_adverts_from_table(adverts_table, page_href)
		adverts_table.each do |advert|
			exists = AutoAdvert.exists?({code: advert[:code]})
			if exists
				ParserMessenger.say_about_existed_advert(advert)
			else
				sleep 5
				ParserMessenger.say_about_advert_parsing(advert, page_href)
				info = AutoAdvertParser.new.get_info(advert[:href])
				AutoAdvert.create_from_info(info)
			end

			return false if needs_stop(advert)
		end

		return true
	end

	# Получает таблицу с объявлениями
	def get_adverts_table(adverts_page)
		adverts = adverts_page.css(@@adverts_table_selector)
		adverts.drop(1).collect do |advert|
			columns = advert.css(@@td_selector)
			info = {
				date: columns[@@adverts_table_columns[:date]].text,
				model: DromParser.strip(columns[@@adverts_table_columns[:model]].text, " \n"),
				href: columns[@@adverts_table_columns[:date]].css(@@a_selector).first[@@href_attribute_selector],
				code: advert.attribute(@@advert_id_attribute).value,
				type: get_advert_type(advert)
			}
		end
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
			last_parsing = ParsingResult.last
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
			last_parsing = ParsingResult.last
			last_parsing.region if last_parsing
		end

		def date_difference_in_days(d1, d2)
			# Разность в секундах / (60 * 60 * 24)
			(d1.to_f - d2.to_f) / 86400.0
		end

		def needs_stop(advert_info)
			now = DateTime.now

			day, month = advert_info[:date].split("-")
			day = day.to_i
			month = month.to_i
			year = (month > now.month) ? now.year - 1 : now.year

			advert_date = DateTime.new(year, month, day, 0, 0, 0)

			date_difference_in_days(now, advert_date) >= 2
		end
end