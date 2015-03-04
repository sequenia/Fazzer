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

	# Типы сохранений объвялений:
	# Бежать до первого прикрепленного
	# Бежать до первого поднятого
	# Бежать до первого обычного
	@@save_types = {
		first_pinned_existed: 'first_pinned_existed',
		first_upped_existed: 'first_upped_existed',
		first_default_existed: 'first_default_existed',
		first_pinned_not_existed: 'first_pinned_not_existed',
		first_upped_not_existed: 'first_upped_not_existed',
		first_default_not_existed: 'first_default_not_existed'
	}

	# Для следующего региона скачивает все прикрепленные объявления.
	# Останавливается при встрече первого обычного объявления, которого нет в БД
	def setup_next_region
		parse_next_region(@@save_types[:first_default_not_existed])
	end

	# Сохраняет последние объявления для следующего.
	# Останавливается, когда встречает обычное объявление, сохраненное в БД
	def save_next_region
		parse_next_region(@@save_types[:first_default_existed])
	end

	# Запускает парсинг для следующего региона, если парсинг не запущен
	def parse_next_region(stop_on)
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

					AutoParser.new.save_last_region_adverts(region.href, stop_on)
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
	def save_last_region_adverts(region_href, stop_on)
		ParserMessenger.say_about_region_parsing(region_href)

		session = new_session
		DromParser.set_region(session)

		page_index = 1
		while save_adverts_from_page(region_href + "page#{page_index}", stop_on, session)
			ParserMessenger.say_about_region_page_parsed(page_index, region_href)
			page_index += 1
		end

		session.driver.quit

		ParserMessenger.say_about_region_parsing_end(region_href)
	end

	# Парсит все объявления со страници и сохраняет их в БД.
	# Возвращает false/nil, если нужно закончить парсинг (Последние объявления закончились),
	# true, если можно продолжать.
	#
	# stop_on = ['first_pinned_existed'|'first_pinned_not_existed'|'first_upped_existed'|'first_upped_not_existed'|'first_default_existed'|'first_default_not_existed']
	def save_adverts_from_page(page_href, stop_on, session)
		sleep 5

		stop_on ||= @@save_types[:first_default_existed]

		if DromParser.visit_page(session, page_href)
			page = Nokogiri::HTML.parse(session.html)
			ParserMessenger.say_about_adverts_table_parsing(page_href)
			adverts_table = get_adverts_table(page)
			ParserMessenger.print_adverts_table(adverts_table)

			if adverts_table.size == 0
				ParserMessenger.say_about_no_adverts(page_href)
				return false
			end

			return save_adverts_from_table(adverts_table, stop_on, page_href) && can_show_next_page(page, page_href)
		end
	end

	def save_adverts_from_table(adverts_table, stop_on, page_href)
		adverts_table.each do |advert|
			exists = AutoAdvert.exists?({code: advert[:code]})
			if exists
				ParserMessenger.say_about_existed_advert(advert)
				if needs_stop_if_exists(advert, stop_on)
					ParserMessenger.say_about_stop_region_parsing(stop_on, advert)
					return false
				end
			else
				sleep 5
				ParserMessenger.say_about_advert_parsing(advert, page_href)
				info = AutoAdvertParser.new.get_info(advert[:href])
				AutoAdvert.create_from_info(info)

				if needs_stop_if_not_exists(advert, stop_on)
					ParserMessenger.say_about_stop_region_parsing(stop_on, advert)
					return false
				end
			end
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

		def needs_stop_if_exists(advert, stop_on)
			stop_on == @@save_types[:first_pinned_existed] && advert[:type] == @@advert_types[:pinned] ||
			stop_on == @@save_types[:first_upped_existed] && advert[:type] == @@advert_types[:upped] ||
			stop_on == @@save_types[:first_default_existed] && advert[:type] == @@advert_types[:default]
		end

		def needs_stop_if_not_exists(advert, stop_on)
			stop_on == @@save_types[:first_pinned_not_existed] && advert[:type] == @@advert_types[:pinned] ||
			stop_on == @@save_types[:first_upped_not_existed] && advert[:type] == @@advert_types[:upped] ||
			stop_on == @@save_types[:first_default_not_existed] && advert[:type] == @@advert_types[:default]
		end

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
end