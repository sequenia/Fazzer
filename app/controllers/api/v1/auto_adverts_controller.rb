class Api::V1::AutoAdvertsController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  # Отдает 5 последних объявлений, подходящих под фильтр params[:filter].
  # Если params[:update_filter] не пустой, то фильтр пользователя обновится.
  def index
    filter = current_user.first_filter
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => filter.nil? ? [] :
                        AutoAdvert.get_min_info
                        .filter(current_user.first_filter.attributes_for_advert)
                        .offset(params[:offset] || 0)
                        .limit(params[:limit] || 10) }
  end

  # Отдает полную информацию об объявлении по переданному id
  def show
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => AutoAdvert.get_full_info.where({id: params[:id]}).first }
  end
end