class AutoAdvertParser < DromParser
	@@advert_text_selector = "td.adv-text"                                 # Контейнер с текстом объяления
	@@advert_header_selector = "#{@@advert_text_selector} h3"              # Контейнер с заголовком объявления
	@@advert_date_selector = "#{@@advert_text_selector} p.autoNum"         # Контейнер с датой объявления
	@@advert_price_selector = "#{@@advert_text_selector} div.price"        # Контейнер с ценой
	@@advert_data_selector = "#{@@advert_text_selector} p span.label"      # Контейнер с данными объяления
	@@advert_contacts_selector = "#{@@advert_text_selector} p#contactsEx"  # Контейрер с 
	@@path_part_selector = "div.path a"                                    # Ссылки с маркой и моделью
	@@photo_selector = "a.bigImage img"                                    # Фотография

	@@phone_visible_class = "contactsExVisible"                            # Класс видимого телефона
	@@show_phones_link_text = "Показать телефон"                           # Текст на ссылке телефона

	@@description_key = "Дополнительно:"
	@@engine_key = "Двигатель:"
	@@class_attribute = "class"
	@@span_selector = "span"
	@@src_attribute = "src"
	@@another_src_attribute = "srctemp"

	attr_accessor :adverts_per_thread, :adverts_per_process

	def initialize
		settings = Setting.first
		if settings
			self.adverts_per_process = settings.adverts_per_process
			self.adverts_per_thread = settings.adverts_per_thread
		else
			self.adverts_per_process = 100
			self.adverts_per_thread = 5
		end
	end

	# Собирает полную информацию о первых adverts_per_process объявлениях
	# из таблицы new_auto_adverts
	def parse_full_info
		# Начинаем парсить только если предыдущий парсинг завершился
		if !parsing_is_in_progress
			ParserMessenger.say_about_parsing_start

			begin
				# Заносим в БД информацию о начале парсинга
				result = ParsingResult.create({
					result_type: "adverts",
					is_parsing: true,
					success: false
				})

				parse_first_adverts

				# После парсинга записываем в бд, что он завершился с успехом
				result.update_attributes({success: true, info: "#{self.adverts_per_process} adverts parsed"})
			rescue Exception => e
				result.update_attributes({success: false, info: e.message}) if result
				puts e.message
				puts e.backtrace.inspect
			ensure
				# В любом случае сообщаем о том, что парсинг завершился
				result.update_attributes({is_parsing: false}) if result
			end
		end
	end

	def parse_first_adverts
		NewAutoAdvert.where({parsed: false})
		.order("id ASC")
		.limit(self.adverts_per_process)
		.in_groups_of(self.adverts_per_thread) do |adverts|
			save_adverts(adverts)
			adverts.each { |advert| advert.update_attributes({parsed: true}) if advert }
		end
	end

	# Собирает полную информацию об объявлениях и сохраняет ее в БД.
	# ВНИМАНИЕ! Страницы грузятся параллельно! Не передавать большое число объявлений за раз!
	def save_adverts(adverts)
		threads = []
		mutex = Mutex.new
		infos = []

		sleep 2

		for advert in adverts
			if advert
				ParserMessenger.say_about_advert_parsing(advert)
				threads << Thread.new(advert) do |thread_advert|
					info = AutoAdvertParser.new.get_info(thread_advert, mutex)
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

	def get_info(advert, mutex)
		session = new_session

		if DromParser.visit_page(session, advert.url)
			mutex.synchronize { ParserMessenger.say_loaded(advert.url) }

			page = Nokogiri::HTML.parse(session.html)
			info = nil

			if !page.at_css(@@advert_text_selector).nil?
				photo_url = PhotosLoader.new.get_photo_url(page)
				photo_preview_url = PhotosLoader.new.get_photo_preview_url(photo_url, page)

				info = {
					code: get_code(page),
					url: advert.url,
					date: get_date(page),
					mark: get_mark(page),
					model: get_model(page),
					year: get_year(page),
					price: get_price(page),
					photo_url: photo_url,
					photo_preview_url: photo_url ? advert.photo_preview_url : photo_preview_url,
					photos_processed: true,
					phones: []
				}

				get_another_data(info, page)
			end

			session.driver.quit
			info
		end
	end

		# Возвращает true, если парсинг уже запущен
		def parsing_is_in_progress
			ParsingResult.where({
				result_type: ParsingResult.result_types[:adverts],
				is_parsing: true
			}).first ? true : false
		end

	private



		def get_phones(session)
			return nil unless session.has_link?(@@show_phones_link_text)

			session.click_link(@@show_phones_link_text)
			phones = nil
			timeout = 0
			max_timeout = 10
			t = 0.1

			# Ждем, пока телефон не появился
			while true
				break if timeout >= max_timeout

				# Проверяем, не спрятался ли контейнер с телефоном
				if session.has_css?(@@advert_contacts_selector, :visible => true)
					phones = get_phones_from_page(session)
					if phones
						break
					else
						sleep t
						timeout += t
					end
				# Если контейнер с телефоном пропал, значит появилась captcha
				else
					ParserMessenger.say_about_captcha
					break
				end
			end

			return phones
		end

		def get_phones_from_page(session)
			page = Nokogiri::HTML.parse(session.html)
			contacts = page.at_css(@@advert_contacts_selector)
			phones = nil

			if contacts[@@class_attribute][@@phone_visible_class]
				phones = []
				contacts.at_css(@@span_selector).children.each do |text|
					if text.text?
						phones << text.text
					end
				end
			end

			return phones
		end

		def get_another_data(info, page)
			page.css(@@advert_data_selector).each do |span|
				key = span.text

				if key == @@description_key
					info[key] = span.parent.text.gsub(/\A#{@@description_key}/, "")
				elsif key == @@engine_key
					text = span.next.text
					info[:fuel] = DromParser.strip(get_substr(text, /\A([^,\d]*)/) || "", " ")
					info[:displacement] = (get_substr(text, /\s*(\d*)\s*куб.см\Z/) || 0).to_f / 1000.0
				else
					info[key] = DromParser.strip(span.next.text, " ")
				end
			end
		end

		def get_data(node, selector, mask)
			sub_node = node.at_css(selector)
			if sub_node
				get_substr(sub_node.text, mask)
			end
		end

		def get_substr(text, mask)
			(text.match(mask) || [])[1]
		end

		def get_code(page)
			get_data(page, @@advert_date_selector, /Объявление ([\s\S]*) от [\d-]*/)
		end

		def get_date(page)
			data = get_data(page, @@advert_date_selector, /Объявление [\s\S]* от ([\d-]*)/)
			if data
				data.to_datetime
			end
		end

		def get_mark(page)
			page.css(@@path_part_selector)[2].text
		end

		def get_model(page)
			page.css(@@path_part_selector)[3].text
		end

		def get_year(page)
			get_data(page, @@advert_header_selector, /[\s\S]*,\s*(\d*)\s*год/)
		end

		def get_price(page)
			get_data(page, @@advert_price_selector, /(\d[\u00a0\s\d]*\d)[\s\u00a0]*руб./).gsub(/[\s\u00a0]+/, "").to_f
		end
end