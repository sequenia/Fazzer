class Api::V1::CarModelsController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def index
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => CarModel.select("id, name, car_mark_id") }
  end

  def version
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => Version.first.car_models }
  end
end