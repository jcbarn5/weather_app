require 'rails_helper'

RSpec.describe "Forecasts", type: :request do

  # Mock the WeatherService class itself
  let(:weather_service) { instance_double(WeatherService) }

  # A simple hash representing the *successful* output of our service
  let(:forecast_data) do
    {
      current_temp: 70,
      current_conditions: "Sunny",
      today_high: 75,
      today_low: 65,
      extended_forecast: [
        { date: 'Friday, Oct 31', high: 72, low: 62, conditions: 'Cloudy' }
      ]
    }
  end

  describe "GET / (root path)" do
    it "loads the search page successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Get the Forecast")
    end
  end

  describe "GET /forecasts" do
    let(:valid_address) { "1600 Amphitheatre Pkwy, Mountain View, CA" }

    context "with a valid address" do
      before do
        # We expect the controller to create a new WeatherService with the address
        allow(WeatherService).to receive(:new).with(valid_address).and_return(weather_service)

        # We expect it to call fetch_forecast and return our mock data
        allow(weather_service).to receive(:fetch_forecast).and_return(forecast_data)

        get forecasts_path, params: { address: valid_address }
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the 'show' template" do
        expect(response).to render_template(:show)
      end

      it "displays the forecasts data" do
        expect(response.body).to include("Weather for #{valid_address}")
        expect(response.body).to include("70°F") # Current temp
        expect(response.body).to include("Friday, Oct 31") # Extended
      end
    end

    context "with a blank address" do
      before do
        get forecasts_path, params: { address: "" }
      end

      it "returns an unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template(:new)
      end

      it "shows an alert message" do
        # For request specs, check the body for the flash message
        expect(response.body).to include("Please enter an address.")
      end
    end

    context "when the address is not found or API fails" do
      before do
        # We mock the service to return nil, as it does on failure
        allow(WeatherService).to receive(:new).with(valid_address).and_return(weather_service)
        allow(weather_service).to receive(:fetch_forecast).and_return(nil)

        get forecasts_path, params: { address: valid_address }
      end

      it "returns a successful response" do
        # The page *loads* successfully, it just shows an error message
        expect(response).to have_http_status(:ok)
      end

      it "renders the 'show' template" do
        expect(response).to render_template(:show)
      end

      it "assigns nil to @forecasts" do
        expect(assigns(:forecasts)).to be_nil
      end
    end
  end
end
