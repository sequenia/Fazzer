class Api::V1::DevicesController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def create
    p = device_params
    user = current_user
    device = Device.where({user_id: user.id, token: p[:token], platform: p[:platform]}).first
    if device.nil?
      device = Device.create(p.merge({user_id: user.id}))
    end

    Device.where({token: device.token}).where.not({user_id: user.id}).each do |d|
       d.update_attributes({enabled: false})
    end

    if device.update_attributes({enabled: true})
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