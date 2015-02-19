class NotificationSender
	# platform - android или ios
	# token - токен девайса
	# message - сообщение
	# params - содержит дополнительные параметры:
	# params = {
	#   badge: 5,     # Количество сообщений, отображаемое в уведомлении
	#   sound: 'name' # Звук оповещения
	# }
	#def self.send(platform, token, message, params)
	#	if platform == "android"
	#		gcm = GCM.new(ENV["GCM_API_KEY"])
	#		registration_ids = [token]
	#		options = {data: {message: message}, collapse_key: "updated_score"}
	#		response = gcm.send(registration_ids, options)
	#	elsif platform == "ios"
	#	end
	#end

	# options = {
	#   data: JSON,         # JSON для отправления на мобильное устройство
	#   collapse_key: "Key" # Назначение сообщения
	# }
	def self.send(platform, token, options)
		options ||= {}
		if platform == "android"
			gcm = GCM.new(ENV["GCM_API_KEY"])

			registration_ids = [token]

			gcm_options = {}
			gcm_options[:data]         = options[:data]         if options[:data]
			gcm_options[:collapse_key] = options[:collapse_key] if options[:collapse_key]

			response = gcm.send(registration_ids, gcm_options)
		elsif platform == "ios"
		end
	end
end