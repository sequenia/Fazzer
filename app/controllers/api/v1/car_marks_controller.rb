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
end