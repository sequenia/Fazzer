class RegionsParser < DromParser
	@@cities_path = "http://auto.drom.ru/cities/"

	# Возвращает ссылки на главные страницы регионов
	def get_regions_hrefs
		session = new_session
		session.visit @@cities_path

		page = Nokogiri::HTML.parse(session.html)
		page.css("div.selectCars a").collect do |a|
			href = a.attribute("href")
			if href.value == "#"
				if a.attribute("open").nil?
					session.click_link(a.text)
					page = Nokogiri::HTML.parse(session.html)
				end

				div = page.at_css("div[id='show_cities_#{a.attribute("region_id").value}']")
				href = div.at_css('a').attribute("href")
			end

			href.value
		end
	end
end