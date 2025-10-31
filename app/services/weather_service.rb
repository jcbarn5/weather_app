class WeatherService
  # Define your dummy address
  DUMMY_ADDRESS = "1000 CandyLand Dr, Charlotte NC 28270"

  def initialize(address)
    @address = address.strip

    unless @address.casecmp(DUMMY_ADDRESS) == 0
      api_key = Rails.application.credentials.open_weather_api_key
      @client = OpenWeather::Client.new(api_key: api_key)
    end
  end

  def fetch_forecast
    zip_code = @address.match(/\b(\d{5})\b/)&.[](1)

    if zip_code.nil?
      Rails.logger.warn "Could not extract zip code from #{@address}. Skipping cache."
      return generate_forecast_data
    end

    # TODO: move caching into caching class later
    # use zip code as the cache key
    Rails.cache.fetch("weather-#{zip_code}", expires_in: 30.minutes) do
      Rails.logger.info "--- CACHE MISS ---"
      Rails.logger.info "Generating new forecast data for zip #{zip_code}"

      generate_forecast_data
    end
  end

  private

  def generate_forecast_data
    if @address.casecmp(DUMMY_ADDRESS) == 0
      Rails.logger.info "Returning mock data for #{@address}"
      return mock_weather_data
    end

    # This is "real" logic for later for when API keys are available
    begin
      coordinates = get_coordinates
      return nil unless coordinates

      data = @client.one_call(lat: coordinates[:lat], lon: coordinates[:lon])
      parse_data(data)

    rescue OpenWeather::Errors::ApiError, Geocoder::Error => e
      Rails.logger.error "API Error for #{@address}: #{e.message}"
      nil
    end
  end

  # mocking data for now without api keys
  def mock_weather_data
    {
      current_temp: 75,
      current_conditions: "Sunny",
      today_high: 80,
      today_low: 65,
      extended_forecast: [
        { date: "Friday, Nov 01", high: 66, low: 60, conditions: "Mostly Sunny" },
        { date: "Saturday, Nov 02", high: 59, low: 44, conditions: "Partly Cloudy" },
        { date: "Sunday, Nov 03", high: 44, low: 42, conditions: "Showers" },
        { date: "Monday, Nov 04", high: 67, low: 60, conditions: "Clear" },
        { date: "Tuesday, Nov 05", high: 70, low: 55, conditions: "Sunny" }
      ]
    }
  end

  def get_coordinates
    result = Geocoder.search(@address).first
    return nil unless result
    { lat: result.latitude, lon: result.longitude }
  end

  def parse_data(data)
    Rails.logger.info "API Response for #{@address}: #{data.inspect}"
    {
      current_temp: data.current.temp.round,
      current_conditions: data.current.weather.first.description.titleize,
      today_high: data.daily.first.temp.max.round,
      today_low: data.daily.first.temp.min.round,
      extended_forecast: data.daily.drop(1).map do |day|
        {
          date: day.dt.strftime("%A, %b %d"),
          high: day.temp.max.round,
          low: day.temp.min.round,
          conditions: day.weather.first.description.titleize
        }
      end
    }
  end
end
