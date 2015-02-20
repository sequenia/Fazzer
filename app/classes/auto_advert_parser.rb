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

	def get_info(href)
		session = new_session

		if DromParser.visit_page(session, href)
			page = Nokogiri::HTML.parse(session.html)

			if !page.at_css(@@advert_text_selector).nil?
				info = {
					code: get_code(page),
					url: href,
					date: get_date(page),
					mark: get_mark(page),
					model: get_model(page),
					year: get_year(page),
					price: get_price(page),
					photo_url: get_photo_url(page),
					phones: []
				}

				get_another_data(info, page)

				session.driver.quit
				ParserMessenger.show_advert_info(info)

				info
			else
				session.driver.quit
				ParserMessenger.say_about_nothing_data
			end
		end
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

		def get_photo_url(page)
			img = page.at_css(@@photo_selector)
			if img
				src = img.attribute(@@src_attribute) || img.attribute(@@another_src_attribute)
				if src
					src.value
				end
			end
		end
end