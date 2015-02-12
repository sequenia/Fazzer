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

    def random_password
      "12345678"
    end

    def sign_up_params
      devise_parameter_sanitizer.sanitize(:sign_up)
    end
end
