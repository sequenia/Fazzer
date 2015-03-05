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

					AutoParser.new.save_region_adverts(region.href)

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

	# Парсит новые объявления с региона
	def save_region_adverts(region_href)
		ParserMessenger.say_about_region_parsing(region_href)

		pages_period = 10    # Со скольки страниц за раз собирать ссылки на объявления
		page_index = 1       # Номер страницы с объявлениями

		# Парсим страницы с объявлениями, пока не преодолеем лимит по дате
		while true
			ParserMessenger.say_about_adverts_table_parsing
			result = get_adverts_table(region_href, pages_period, page_index)
			
			ParserMessenger.print_adverts_table(result[:adverts_table])
			save_adverts_from_table(result[:adverts_table])
			page_index = result[:page_index]
			AutoFilter.check_new_adverts

			break if !result[:can_continue]
		end

		ParserMessenger.say_about_region_parsing_end(region_href)
	end

	# Возвращает объявления с pages_period страниц, начиная с page_index
	def get_adverts_table(region_href, pages_period, page_index)
		# Если преодолели лимит страниц, заканчиваем
		return { adverts_table: [], can_continue: false, page_index: page_index } if page_index >= 100

		session = new_session
		DromParser.set_region(session)
		new_page_index = page_index

		# Собираем ссылки на объявления с pages_period страниц
		adverts_table = []
		(0...pages_period).each do |i|
			# Если преодолели лимит страниц, заканчиваем
			if page_index >= 100
				session.driver.quit
				return { adverts_table: [], can_continue: false, page_index: page_index }
			end

			sleep 2
			if DromParser.visit_page(session, region_href + "page#{new_page_index}")
				page = Nokogiri::HTML.parse(session.html)
				can_continue = get_adverts_table_from_page(adverts_table, page)
				# Если преодолели лимит по дате, заканчиваем
				if !can_continue
					session.driver.quit
					return { adverts_table: adverts_table, can_continue: false, page_index: new_page_index }
				end
			end
			new_page_index += 1
		end
		session.driver.quit

		result = {
			adverts_table: adverts_table,
			can_continue: true,
			page_index: new_page_index
		}
	end

	# Получает таблицу с новыми объявлениями со страницы.
	# Если преодолен лимит по дате, возвращает false
	def get_adverts_table_from_page(adverts_table, adverts_page)
		adverts = adverts_page.css(@@adverts_table_selector)
		adverts.drop(1).each do |advert|
			columns = advert.css(@@td_selector)
			code = advert.attribute(@@advert_id_attribute).value
			date = columns[@@adverts_table_columns[:date]].text

			if needs_stop(date)
				puts "Date limit succeed! #{date}"
				return false
			end

			if AutoAdvert.exists?({code: code})
				ParserMessenger.say_about_existed_advert(code)
			else
				adverts_table << {
					date: date,
					model: DromParser.strip(columns[@@adverts_table_columns[:model]].text, " \n"),
					href: columns[@@adverts_table_columns[:date]].css(@@a_selector).first[@@href_attribute_selector],
					code: advert.attribute(@@advert_id_attribute).value,
					type: get_advert_type(advert)
				}
			end
		end

		return true
	end

	def save_adverts_from_table(adverts_table)
		adverts_table.each do |advert|
			sleep 2
			ParserMessenger.say_about_advert_parsing(advert)
			info = AutoAdvertParser.new.get_info(advert[:href])
			AutoAdvert.create_from_info(info)
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