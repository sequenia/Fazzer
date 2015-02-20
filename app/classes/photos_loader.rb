class PhotosLoader < DromParser
	@@photo_selector = "a.bigImage img"
	@@src_attribute = "src"
	@@another_src_attribute = "srctemp"

	def load_photos
		AutoAdvert.where(photo_url: nil).where.not(url: nil).order("id").each do |advert|
			session = new_session
			if DromParser.visit_page(session, advert.url)
				page = Nokogiri::HTML.parse(session.html)

				photo_url = get_photo_url(page)
				advert.update_attributes({photo_url: photo_url}) if photo_url

				session.driver.quit

				sleep 5
			end
		end
	end

	private

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