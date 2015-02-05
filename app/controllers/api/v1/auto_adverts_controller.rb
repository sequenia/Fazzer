class Api::V1::AutoAdvertsController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  # Just skip the authentication for now
  before_filter :authenticate_user!

  respond_to :json

  def index
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => { auto_adverts: AutoAdvert.get_min_info.filter(current_user.first_filter).limit(5) } }
  end
end