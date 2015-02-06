class Api::V1::AutoFiltersController < ApplicationController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :authenticate_user!

  respond_to :json

  def create
    current_user.update_or_create_filter(params)
  end
end