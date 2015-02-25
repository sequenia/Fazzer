class Api::V1::AutoFiltersController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def create
    # Разрешаем пустые параметры
    parameters = (params[:auto_filter] || {}).empty? ? {} : filter_params
    filter = current_user.update_or_create_filter(parameters)
    response = {}

    if filter
      response = {
        :success => true,
        :info => "ok"
      }
    else
      response = {
        :success => false,
        :info => filter.error
      }
    end

    render :status => 200,
           :json => response
  end

  private

    def filter_params
      params.require(:auto_filter).permit(:car_mark_id, :car_model_id, :min_price, :max_price, :min_year, :max_year, :city_id)
    end
end