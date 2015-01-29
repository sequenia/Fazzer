require "open-uri"
require 'capybara'
require 'capybara/poltergeist'

class DromParser
	include Capybara::DSL

	# Новая сессия
	def new_session
		session = Capybara::Session.new(:poltergeist)

		session.driver.headers = { 'User-Agent' =>
			DromParser.random_desktop_user_agent }

		session
	end

	def self.visit_page(session, page)
		puts "Loading page #{page}"

		attempts = 0
		max_attempts = 5
		result = nil

		while true
			begin
				session.visit page
				puts "Loaded!"
				result = true
				break
			rescue Capybara::Poltergeist::TimeoutError => ex
				puts "ERROR #{ex.class}: #{ex.message}"
				attempts += 1
			rescue Exception => ex
				puts "ERROR #{ex.class}: #{ex.message}"
				attempts += 1
			end

			if attempts >= max_attempts
				session.driver.quit
				break
			end
		end

		return result
	end

	def self.strip(str1, str2)
		str1.gsub(/\A[#{str2}]+|[#{str2}]+\Z/, "")
	end

	def self.random_desktop_user_agent
		user_agents = [
			"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
			"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:16.0) Gecko/20100101 Firefox/16.0",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17",
			"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)",
			"Mozilla/5.0 (Windows NT 5.1; rv:13.0) Gecko/20100101 Firefox/13.0.1",
			"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; FunWebProducts; .NET CLR 1.1.4322; PeoplePal 6.2)",
			"Mozilla/5.0 (Windows NT 5.1; rv:5.0.1) Gecko/20100101 Firefox/5.0.1",
			"Mozilla/5.0 (Windows NT 6.0) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 Safari/535.1",
			"Opera/9.80 (Windows NT 5.1; U; en) Presto/2.10.289 Version/12.01",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.95 Safari/537.11",
			"Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)",
			"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) )",
			"Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727)",
			"Mozilla/5.0 (Windows NT 6.1; rv:2.0b7pre) Gecko/20100921 Firefox/4.0b7pre",
			"Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322)",
			"Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.95 Safari/537.11",
			"Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; .NET CLR 3.5.30729)",
			"Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.95 Safari/537.11",
			"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 Safari/535.1",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
			"Mozilla/4.0 (compatible; MSIE 6.0; MSIE 5.5; Windows NT 5.0) Opera 7.02 Bork-edition [en]",
			"Mozilla/5.0 (Windows NT 6.1; rv:5.0) Gecko/20100101 Firefox/5.02",
			"Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
			"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20100101 Firefox/5.0",
			"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; MRA 5.8 (build 4157); .NET CLR 2.0.50727; AskTbPTV/5.11.3.15590)",
			"Mozilla/5.0 (Windows NT 5.1; rv:16.0) Gecko/20100101 Firefox/16.0",
			"Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
			"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0",
			"Mozilla/5.0 (Windows NT 6.1; rv:16.0) Gecko/20100101 Firefox/16.0",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.57.2 (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2",
			"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)",
			"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.91 Safari/537.11",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0",
			"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/17.0 Firefox/17.0",
			"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; TencentTraveler ; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; .NET CLR 2.0.50727)",
			"Mozilla/5.0 (iPad; CPU OS 6_0_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A523 Safari/8536.25",
			"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:16.0) Gecko/20100101 Firefox/16.0",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.95 Safari/537.11",
			"Mozilla/5.0 (Windows NT 5.1; rv:17.0) Gecko/20100101 Firefox/17.0",
			"Mozilla/5.0 (Windows NT 5.1; rv:17.0) Gecko/20100101 Firefox/17.0"]
		return user_agents.sample
	end

	def self.get_regions
		regions = [
			"http://auto.drom.ru/region22/all/",
			"http://auto.drom.ru/region28/all/",
			"http://auto.drom.ru/region29/all/",
			"http://auto.drom.ru/region30/all/",
			"http://auto.drom.ru/region31/all/",
			"http://auto.drom.ru/region32/all/",
			"http://auto.drom.ru/region33/all/",
			"http://auto.drom.ru/region34/all/",
			"http://auto.drom.ru/region35/all/",
			"http://auto.drom.ru/region36/all/",
			"http://auto.drom.ru/region79/all/",
			"http://auto.drom.ru/region101/all/",
			"http://auto.drom.ru/region37/all/",
			"http://auto.drom.ru/region38/all/",
			"http://auto.drom.ru/region7/all/",
			"http://auto.drom.ru/region39/all/",
			"http://auto.drom.ru/region40/all/",
			"http://auto.drom.ru/region41/all/",
			"http://auto.drom.ru/region9/all/",
			"http://auto.drom.ru/region42/all/",
			"http://auto.drom.ru/region43/all/",
			"http://auto.drom.ru/region44/all/",
			"http://auto.drom.ru/region23/all/",
			"http://auto.drom.ru/region24/all/",
			"http://auto.drom.ru/region45/all/",
			"http://auto.drom.ru/region46/all/",
			"http://auto.drom.ru/region47/all/",
			"http://auto.drom.ru/region48/all/",
			"http://auto.drom.ru/region49/all/",
			"http://moscow.drom.ru/auto/all/",
			"http://auto.drom.ru/region50/all/",
			"http://auto.drom.ru/region51/all/",
			"http://naryan-mar.drom.ru/auto/all/",
			"http://auto.drom.ru/region52/all/",
			"http://auto.drom.ru/region53/all/",
			"http://auto.drom.ru/region54/all/",
			"http://auto.drom.ru/region55/all/",
			"http://auto.drom.ru/region56/all/",
			"http://auto.drom.ru/region57/all/",
			"http://auto.drom.ru/region58/all/",
			"http://auto.drom.ru/region59/all/",
			"http://auto.drom.ru/region25/all/",
			"http://auto.drom.ru/region60/all/",
			"http://auto.drom.ru/region1/all/",
			"http://auto.drom.ru/region4/all/",
			"http://auto.drom.ru/region2/all/",
			"http://auto.drom.ru/region3/all/",
			"http://auto.drom.ru/region5/all/",
			"http://auto.drom.ru/region6/all/",
			"http://auto.drom.ru/region8/all/",
			"http://auto.drom.ru/region10/all/",
			"http://auto.drom.ru/region11/all/",
			"http://auto.drom.ru/region102/all/",
			"http://auto.drom.ru/region12/all/",
			"http://auto.drom.ru/region13/all/",
			"http://auto.drom.ru/region14/all/",
			"http://auto.drom.ru/region15/all/",
			"http://auto.drom.ru/region16/all/",
			"http://auto.drom.ru/region17/all/",
			"http://auto.drom.ru/region19/all/",
			"http://auto.drom.ru/region61/all/",
			"http://auto.drom.ru/region62/all/",
			"http://auto.drom.ru/region63/all/",
			"http://spb.drom.ru/auto/all/",
			"http://auto.drom.ru/region64/all/",
			"http://auto.drom.ru/region65/all/",
			"http://auto.drom.ru/region66/all/",
			"http://auto.drom.ru/region67/all/",
			"http://auto.drom.ru/region26/all/",
			"http://auto.drom.ru/region68/all/",
			"http://auto.drom.ru/region69/all/",
			"http://auto.drom.ru/region70/all/",
			"http://auto.drom.ru/region71/all/",
			"http://auto.drom.ru/region72/all/",
			"http://auto.drom.ru/region18/all/",
			"http://auto.drom.ru/region73/all/",
			"http://auto.drom.ru/region27/all/",
			"http://auto.drom.ru/region86/all/",
			"http://auto.drom.ru/region74/all/",
			"http://auto.drom.ru/region20/all/",
			"http://auto.drom.ru/region21/all/",
			"http://bilibino.drom.ru/auto/all/",
			"http://auto.drom.ru/region89/all/",
			"http://auto.drom.ru/region76/all/"
		]
	end
end