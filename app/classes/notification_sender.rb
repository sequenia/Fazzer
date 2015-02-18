class NotificationSender
	# platform - android или ios
	# token - токен девайса
	# message - сообщение
	# params - содержит дополнительные параметры:
	# params = {
	#   badge: 5,     # Количество сообщений, отображаемое в уведомлении
	#   sound: 'name' # Звук оповещения
	# }
	def self.send(platform, token, message, params)
		if platform == "android"
			gcm = GCM.new(ENV["GCM_API_KEY"])
			registration_ids = [token]
			options = {data: {message: message}, collapse_key: "updated_score"}
			response = gcm.send(registration_ids, options)
		elsif platform == "ios"
		end
	end
end