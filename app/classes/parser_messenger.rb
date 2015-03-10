class ParserMessenger

	def self.say_about_parsing_start
		puts "Start parsing on #{DateTime.now}"
	end

	def self.say_about_no_next_region
		puts "Can't find next region"
	end

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

	def self.say_about_adverts_table_parsing
		puts "Getting adverts table"
	end

	def self.print_adverts_table(adverts_table)
		puts "Adverts: #{adverts_table.collect{ |a| a[:code] + " " + a[:type] }.join(", ")}"
	end

	def self.say_about_no_adverts(page_href)
		puts "ERROR! No adverts on page #{page_href}"
	end

	def self.say_about_existed_advert(code)
		puts "Advert already exists: #{code}"
	end

	def self.say_about_stop_region_parsing(stop_on, advert)
		puts "STOP! Stop on #{stop_on}. Advert: #{advert}"
	end

	def self.say_about_advert_parsing(advert)
		puts "Getting full info for #{advert.url} with code #{advert.code} on #{advert.region_href}"
	end

	def self.say_about_pager_missing(page_href)
		puts "NO PAGER AT PAGE #{page_href}"
	end

	def self.show_advert_info(info)
		puts "Info for #{info[:mark]} #{info[:model]} parsed. Advert code: #{info[:code]}" if info
	end

	def self.say_about_nothing_data
		puts "ERROR: no data on advert page!"
	end

	def self.say_about_captcha
		puts "ERROR while getting phone: CAPTCHA"
	end

	def self.show_mark_name(name)
		puts "------ МАРКА " + name
	end

	def self.show_model_name(name)
		puts "МОДЕЛЬ: " + name
	end
end