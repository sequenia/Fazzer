class Api::V1::DevicesController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def create
    device = Device.new(device_params.merge({user_id: current_user.id}))
    if device.save
      render :status => 200,
             :json => { :success => true,
                      :info => "Device created",
                      :data => device }
    else
      render :status => 422,
             :json => { :success => false,
                      :info => "Unprocessable entity",
                      :data => device.errors }
    end
  end

  private

    def device_params
      params.require(:device).permit(:token, :platform)
    end
end