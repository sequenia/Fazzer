class FazzerMailer < ApplicationMailer
	default from: 'FazzerMailer@gmail.com'

	def new_adverts_message(adverts, filter, email)
		@adverts = adverts
		@filter = filter

		subject = "Объявления на drom.ru"

		mail(to: email, subject: subject)
	end
end
