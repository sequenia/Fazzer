class Api::V1::AutoAdvertsController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  # Just skip the authentication for now
  before_filter :authenticate_user!

  respond_to :json

  # Отдает 5 последних объявлений, подходящих под фильтр params[:filter].
  # Если params[:update_filter] не пустой, то фильтр пользователя обновится.
  def index
    if params[:update_filter]
      current_user.update_filter(params[:filter])
    end
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => { auto_adverts: AutoAdvert.get_min_info.filter(params[:filter]).limit(5) } }
  end

  # Отдает полную информацию об объявлении по переданному id
  def show
    render :status => 200,
           :json => { :success => true,
                      :info => "ok",
                      :data => { auto_advert: AutoAdvert.get_full_info.where({id: params[:id]}).first } }
  end
end