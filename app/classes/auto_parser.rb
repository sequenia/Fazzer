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
						region_id: region.id,
						is_parsing: true,
						success: false
					})

					# Ищем на сайте новые объявления и сохраняем их
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

	# Сохраняет в БД новые объявления с региона за последние 2 дня.
	# Собирает данные со страниц порциями по pages_period штук.
	def save_region_adverts(region_href)
		ParserMessenger.say_about_region_parsing(region_href)

		pages_period = 10    # Со скольки страниц за раз собирать ссылки на объявления
		page_index = 1       # Номер текущей страницы с объявлениями

		# Парсим страницы с объявлениями, пока не преодолеем лимит по дате или по страницам
		while save_region_part(region_href, pages_period, page_index)
			page_index += pages_period
		end

		ParserMessenger.say_about_region_parsing_end(region_href)
	end

	# Сохраняет объявления с pages_period страниц, начиная с page_index.
	# Возвращает true, если можно продолжать работу
	def save_region_part(region_href, pages_period, page_index)
		ParserMessenger.say_about_adverts_table_parsing
		# Получаем ссылки на объявления с pages_period страниц, загружаем их и сохраняем в БД
		get_adverts_table(region_href, pages_period, page_index) do |adverts_table|
			ParserMessenger.print_adverts_table(adverts_table)
			adverts_table.in_groups_of(3) { |adverts| save_adverts_from_table(adverts) }
			AutoFilter.check_new_adverts
		end
	end

	# Собирает ссылки на объявления с pages_period страниц, начиная с page_index,
	# И передает таблицу объявлений в замыкание closure.
	# Возвращает true, если можно продолжать работу.
	def get_adverts_table(region_href, pages_period, page_index, &closure)
		return false if page_index >= 100

		session = new_session
		new_page_index = page_index
		result = true
		adverts_table = []

		DromParser.set_region(session) # Задаем регион для корректного отображения объявлений

		# Собираем ссылки на объявления с pages_period страниц
		(0...pages_period).each do |i|
			# Если преодолели лимит страниц, заканчиваем
			if page_index >= 100
				result = false
				break
			end

			sleep 2
			page_href = region_href + "page#{new_page_index}"

			ParserMessenger.say_about_page_loading(page_href)
			if DromParser.visit_page(session, page_href)
				page = Nokogiri::HTML.parse(session.html)
				# Если преодолели лимит по дате или нельзя показать следующую страницу, заканчиваем
				if !(get_adverts_table_from_page(adverts_table, page, page_href) && can_show_next_page(page, page_href))
					result = false
					break
				end
			end
			new_page_index += 1
		end
		session.driver.quit

		# Выполняем работу над объявлениями
		closure ||= lambda{ }
		closure.call(adverts_table)

		result
	end

	# Дописывает новые объявления со страницы в массив adverts_table.
	# Если преодолен лимит по дате, возвращает false.
	def get_adverts_table_from_page(adverts_table, adverts_page, page_href)
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
					type: get_advert_type(advert),
					page_href: page_href
				}
			end
		end

		return true
	end

	# Собирает полную информацию об объявлениях и сохраняет ее в БД.
	# ВНИМАНИЕ! Страницы грузятся параллельно! Не передавать большое число объявлений за раз!
	def save_adverts_from_table(adverts)
		threads = []
		mutex = Mutex.new
		infos = []

		sleep 2

		for advert in adverts
			if advert
				ParserMessenger.say_about_advert_parsing(advert)
				threads << Thread.new(advert) do |thread_advert|
					info = AutoAdvertParser.new.get_info(thread_advert[:href])
					mutex.synchronize { infos << info }
				end
			end
		end
		threads.each {|thr| thr.join }

		infos.each do |info|
			ParserMessenger.show_advert_info(info)
			AutoAdvert.create_from_info(info)
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