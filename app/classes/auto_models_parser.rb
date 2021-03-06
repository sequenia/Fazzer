class AutoModelsParser < DromParser
	@@marks_path = "http://auto.drom.ru/"
	@@marks_selector = "div.selectCars td a"
	@@models_selector = "div.selectCars td a"
	@@href_attibute = "href"

	def save_marks
		session = new_session

		if DromParser.visit_page(session, @@marks_path)
			page = Nokogiri::HTML.parse(session.html)

			page.css(@@marks_selector).each do |mark|
				name = mark.text.strip
				ParserMessenger.show_mark_name(name)

				m = CarMark.find_or_create_by_name(name)

				href = mark.attribute(@@href_attibute)
				if href
					sleep 4
					save_models(href.value, m.id)
				end
			end

			session.driver.quit
		end
	end

	def save_models(href, mark_id)
		session = new_session

		if DromParser.visit_page(session, href)
			page = Nokogiri::HTML.parse(session.html)

			page.css(@@models_selector).each do |model|
				name = model.text.strip
				ParserMessenger.show_model_name(name)
				m = CarModel.find_or_create_by_name_and_mark(name, mark_id)
			end

			session.driver.quit
		end
	end
end