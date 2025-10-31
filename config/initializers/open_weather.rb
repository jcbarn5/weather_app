OpenWeather::Client.configure do |config|
  config.api_key = Rails.application.credentials.dig(:open_weather, :api_key)
  config.units = 'imperial' # Use 'metric' for Celsius
end