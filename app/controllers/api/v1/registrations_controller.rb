class Api::V1::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  respond_to :json

  def create
    password = random_password
    build_resource(sign_up_params.merge({
      password: password,
      password_confirmation: password
    }))
    if resource.save
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
      api_id = "05460884-7559-8db4-8d7b-ccf7103c01ed"
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
