class Api::V1::CarMarksController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!, only: :version

  respond_to :json

  def index
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => CarMark.select("id, name") }
  end

  def version
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => Version.first.car_marks }
  end

  def get_car_marks
    car_marks = CarMark.all.collect do |car_mark|
      info = {
        name: car_mark.name,
        car_models: car_mark.car_models.collect { |car_model| { name: car_model.name } }
      }
    end

    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => car_marks }
  end
end