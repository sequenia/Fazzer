class Api::V1::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  respond_to :json

  def create
    password = random_password

    user = nil
    if params[:user]
      if params[:user][:phone]
        user = User.where({phone: params[:user][:phone]}).first
        user.update_attributes({
          password: password,
          password_confirmation: password
        }) if user
      end
    end

    build_resource(sign_up_params.merge({
      password: password,
      password_confirmation: password
    }))

    if resource.save || user
      send_sms(resource.phone, password)
      render :status => 200,
           :json => { :success => true,
                      :info => "Код отправлен",
                      :data => { :user => resource } }
    else
      render :status => :unprocessable_entity,
             :json => { :success => false,
                        :info => resource.errors,
                        :data => {} }
    end
  end

  private

    def send_sms(phone, password)
      api_id = ENV["SMS_API_ID"]
      text = URI.encode("Код для входа: #{password}")
      uri = URI("http://sms.ru/sms/send?api_id=#{api_id}&to=#{phone}&text=#{text}")
      Net::HTTP.get(uri)
    end

    def random_password
      (0..5).map{ |n| rand(9).to_s }.join
    end

    def sign_up_params
      devise_parameter_sanitizer.sanitize(:sign_up)
    end
end
