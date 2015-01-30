class AutoParser < DromParser
	@@adverts_table_selector = "div.tab1 table tr" # Строки таблицы с объявлениями
	@@pager_selector = "div.pager"
	@@td_selector = "td"
	@@a_selector = "a"
	@@href_attribute_selector = "href"
	@@advert_id_attribute = "data-bull-id"
	@@class_attribute = "class"
	@@img_selector = "img"

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

	# Для каждого региона скачивает все прикрепленные объявления
	# Останавливается при встрече первого обычного объявления, которого нет в БД
	def setup_last_adverts
		DromParser.get_regions.each do |region|
			AutoParser.new.save_last_region_adverts(region, @@save_types[:first_default_not_existed])
		end
	end

	# Сохраняет последние объявления для всех регионов.
	# Останавливается, когда встречает обычное объявление, сохраненное в БД
	def save_last_adverts
		DromParser.get_regions.each do |region|
			AutoParser.new.save_last_region_adverts(region, @@save_types[:first_default_existed])
			AutoFilter.check_new_adverts
		end
	end

	# Сохраняет в БД последние объявления с переданного региона
	def save_last_region_adverts(region_href, stop_on)
		ParserMessenger.say_about_region_parsing(region_href)

		page_index = 1
		while save_adverts_from_page(region_href + "page#{page_index}", stop_on)
			ParserMessenger.say_about_region_page_parsed(page_index, region_href)
			page_index += 1
		end

		ParserMessenger.say_about_region_parsing_end(region_href)
	end

	# Парсит все объявления со страници и сохраняет их в БД.
	# Возвращает false/nil, если нужно закончить парсинг (Последние объявления закончились),
	# true, если можно продолжать.
	#
	# stop_on = ['first_pinned_existed'|'first_pinned_not_existed'|'first_upped_existed'|'first_upped_not_existed'|'first_default_existed'|'first_default_not_existed']
	def save_adverts_from_page(page_href, stop_on)
		stop_on ||= @@save_types[:first_default_existed]

		session = new_session

		if DromParser.visit_page(session, page_href)
			page = Nokogiri::HTML.parse(session.html)
			ParserMessenger.say_about_adverts_table_parsing(page_href)
			adverts_table = get_adverts_table(page)
			ParserMessenger.print_adverts_table(adverts_table)
			session.driver.quit

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
					ParserMessenger.say_about_stop_region_parsing(stop_on)
					return false
				end
			else
				sleep 5
				ParserMessenger.say_about_advert_parsing(advert, page_href)
				info = AutoAdvertParser.new.get_info(advert[:href])
				AutoAdvert.create_from_info(info)

				if needs_stop_if_not_exists(advert, stop_on)
					ParserMessenger.say_about_stop_region_parsing(stop_on)
					return false
				end
			end
		end

		return true
	end

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
				type: get_advert_type(columns[@@adverts_table_columns[:date]])
			}
		end
	end

	# default, pinned, upped
	def get_advert_type(date_column)
		image = date_column.at_css(@@img_selector)
		if image
			image[@@class_attribute]
		else
			return @@advert_types[:default]
		end
	end
end