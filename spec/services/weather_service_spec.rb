require 'rails_helper'

module OpenWeather
  module Errors
    class ApiError < StandardError; end
  end
end

RSpec.describe WeatherService, type: :service do
  let(:address) { "123 Main St, Anytown, USA 12345" }
  let(:service) { WeatherService.new(address) }

  let(:coordinates) { { lat: 37.422, lon: -122.084 } }
  let(:geocoder_result) { double('GeocoderResult', latitude: coordinates[:lat], longitude: coordinates[:lon]) }

  let(:weather_client) { instance_double(OpenWeather::Client) }

  let(:mock_weather) { double('Weather', description: 'Clear Sky') }
  let(:mock_current) { double('Current', temp: 75.0, weather: [ mock_weather ]) }

  let(:mock_temp_today) { double('Temp', max: 80.0, min: 60.0) }
  let(:mock_day_today) { double('Day', dt: Time.parse("2025-10-30"), temp: mock_temp_today, weather: [ mock_weather ]) }

  let(:mock_temp_tomorrow) { double('Temp', max: 82.0, min: 62.0) }
  let(:mock_day_tomorrow) { double('Day', dt: Time.parse("2025-10-31"), temp: mock_temp_tomorrow, weather: [ mock_weather ]) }

  let(:api_response) do
    double('APIResponse',
           current: mock_current,
           daily: [ mock_day_today, mock_day_tomorrow ]
    )
  end


  context 'when given a valid address' do
    before do
      allow(Geocoder).to receive(:search).with(address).and_return([ geocoder_result ])

      allow(OpenWeather::Client).to receive(:new).and_return(weather_client)

      allow(weather_client).to receive(:one_call)
                                 .with(lat: coordinates[:lat], lon: coordinates[:lon])
                                 .and_return(api_response)
    end

    it 'returns a parsed forecasts hash' do
      forecast = service.fetch_forecast

      expect(forecast).to be_a(Hash)

      expect(forecast[:current_temp]).to eq(75)
      expect(forecast[:current_conditions]).to eq('Clear Sky')

      expect(forecast[:today_high]).to eq(80)
      expect(forecast[:today_low]).to eq(60)

      expect(forecast[:extended_forecast].count).to eq(1)
      expect(forecast[:extended_forecast].first[:high]).to eq(82)
      expect(forecast[:extended_forecast].first[:date]).to eq('Friday, Oct 31')
    end
  end

  context 'when given an invalid address' do
    before do
      allow(Geocoder).to receive(:search).with(address).and_return([])

      allow(OpenWeather::Client).to receive(:new).and_return(weather_client)
    end

    it 'returns nil' do
      expect(service.fetch_forecast).to be_nil
    end

    it 'does not call the weather API' do
      expect(weather_client).not_to receive(:one_call)
      service.fetch_forecast
    end
  end

  context 'when the weather API raises an error' do
    before do
      allow(Geocoder).to receive(:search).with(address).and_return([ geocoder_result ])

      allow(OpenWeather::Client).to receive(:new).and_return(weather_client)

      allow(weather_client).to receive(:one_call)
                                 .with(lat: coordinates[:lat], lon: coordinates[:lon])
                                 .and_raise(OpenWeather::Errors::ApiError.new("Invalid API key"))

      allow(Rails.logger).to receive(:error)
    end
  end
end
