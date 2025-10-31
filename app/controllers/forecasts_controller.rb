class ForecastsController < ApplicationController

  def new
  end

  def show
    @address = params[:address]

    if @address.present?
      service = WeatherService.new(@address)
      @forecast = service.fetch_forecast
    else
      flash.now[:alert] = "Please enter an address."
      render :new, status: :unprocessable_entity
    end
  end
end