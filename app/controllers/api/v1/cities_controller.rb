class Api::V1::CitiesController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def index
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => City.select("id, name") }
  end
end