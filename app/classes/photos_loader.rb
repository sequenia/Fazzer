class PhotosLoader < DromParser
	@@photo_selector = "a.bigImage img"
	@@src_attribute = "src"
	@@another_src_attribute = "srctemp"
	@@photos_container = "div#usual_photos"

	def load_photos
		AutoAdvert.where({photos_processed: false}).where.not(url: nil).order("id DESC").each do |advert|
			session = new_session
			if DromParser.visit_page(session, advert.url)
				page = Nokogiri::HTML.parse(session.html)

				photo_url = get_photo_url(page)
				if photo_url
					advert.photo_url = photo_url
					photo_preview_url = get_photo_preview_url(photo_url, page)
					if photo_preview_url
						advert.photo_preview_url = photo_preview_url
					end
				end

				advert.photos_processed = true
				advert.save

				session.driver.quit

				sleep 5
			end
		end
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

	def get_photo_preview_url(photo_url, page)
		if photo_url
			img = page.at_css("a[href='#{photo_url}']:not(.bigImage) img")

			if img.nil?
				img = page.at_css("#{@@photos_container} a:not(.bigImage) img")
			end

			if img
				src = img.attribute(@@src_attribute) || img.attribute(@@another_src_attribute)
				if src
					src.value
				end
			end
		end
	end
end