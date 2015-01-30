class ParserMessenger

	def self.say_about_page_loading(page_href)
		puts "Loading page #{page_href}"
	end

	def self.say_loaded(page_href)
		puts "page #{page_href} loaded"
	end

	def self.print_exception(ex)
		puts "ERROR #{ex.class}: #{ex.message}"
	end

	def self.say_about_region_parsing(region_href)
		puts "----- Parsing region #{region_href} -----"
	end

	def self.say_about_region_page_parsed(page_index, region_href)
		puts "Page #{page_index} for region #{region_href} parsed"
	end

	def self.say_about_region_parsing_end(region_href)
		puts "Parsed all new adverts from #{region_href}\n"
	end

	def self.say_about_adverts_table_parsing(page_href)
		puts "Getting adverts table from page #{page_href}"
	end

	def self.print_adverts_table(adverts_table)
		puts "Adverts: #{adverts_table.collect{ |a| a[:code] }.join(", ")}"
	end

	def self.say_about_no_adverts(page_href)
		puts "ERROR! No adverts on page #{page_href}"
	end

	def self.say_about_existed_advert(advert)
		puts "Advert already exists: #{advert[:code]}"
	end

	def self.say_about_stop_region_parsing(stop_on)
		puts "STOP! Stop on #{stop_on}"
	end

	def self.say_about_advert_parsing(advert, page_href)
		puts "Getting full info for #{advert[:type]} #{advert[:model]} on page #{page_href}"
	end

	def self.say_about_pager_missing(page_href)
		puts "NO PAGER AT PAGE #{page_href}"
	end

	def self.show_advert_info(info)
		puts "Info for #{info[:mark]} #{info[:model]} parsed. Advert code: #{info[:code]}"
	end

	def self.say_about_nothing_data
		puts "ERROR: no data on advert page!"
	end

	def self.say_about_captcha
		puts "ERROR while getting phone: CAPTCHA"
	end
end