# README
* Ruby version - 3.4.7

Weather Forecast App
This application allows users to enter a street address and receive the current weather and a 5-day forecast.

Ruby on Rails 8.1

Geocoder for address-to-coordinate lookup
OpenWeather API for forecast data

Generic Rails Caching (30-minute expiration by zip code)

Required Setup


- Install Gems
bundle install

- Add API Keys

- To run this application, you must provide API keys for the geocoding and weather services

- Run the following command to edit the credentials file:

Bash
bin/rails credentials:edit
Add the following keys to the file. You will need to sign up for accounts with 
    Google Maps Geocoding API (or another Geocoder provider) and OpenWeather to get these.


# config/credentials.yml.enc

geocoder_api_key: "YOUR_GOOGLE_GEOCODING_API_KEY_GOES_HERE"
open_weather_api_key: "YOUR_OPEN_WEATHER_API_KEY_GOES_HERE"


- Configure Initializers
The app requires two initializers to function:

# config/initializers/geocoder.rb
Geocoder.configure(
lookup: :google,
use_https: true,
api_key: Rails.application.credentials.geocoder_api_key,
timeout: 5
)

# config/initializers/certifi.rb
ENV['SSL_CERT_FILE'] = Certifi.where

rails s
Open your browser and navigate to http://localhost:3000.

Development Mode (No Keys)
The service is hardcoded with a dummy address to allow for development without API keys. 
    To test, enter this address: 1000 CandyLand Dr, Charlotte NC 28270

Running Tests
- bundle exec rspec

# Application Architecture
This application follows a simple Service Object design pattern to separate business logic from the controller.

## Component Decomposition
The application's logic is broken down into two main objects:

- ForecastsController

  - Responsibility: To handle web requests and responses.

  - It does not know how to fetch or parse a forecast.

  - It only receives the address from the user.

  - It calls the WeatherService and trusts it to return either a forecast hash or nil.

  - It decides what to render based on that result (either the forecast or an error message).

- WeatherService

  - Responsibility: To contain all business logic for fetching and processing a forecast.

  - It is the only part of the app that knows about Geocoder, the OpenWeather client, or API keys.

  - fetch_forecast (Public Method): This is the main entry point. It's responsible only for caching. It extracts a zip code from the address and wraps the main logic in a Rails.cache.fetch block.

  - generate_forecast_data (Private Method): This contains the actual work, which is only executed on a cache miss. It coordinates the other private methods.

  - get_coordinates (Private Method): Handles the Geocoder API call.

  - parse_data (Private Method): Handles formatting the raw data from the OpenWeather API.

  - mock_weather_data (Private Method): Returns hardcoded data if the DUMMY_ADDRESS is used, skipping all API calls.

## Request Workflow
Here is the step-by-step data flow for a typical request:

1. A user submits an address to ForecastsController#show.

2. The controller creates a WeatherService instance with the address.

3. The controller calls service.fetch_forecast.

4. The WeatherService extracts the zip code from the address (e.g., "28270").

5. It asks Rails.cache for a key like weather-28270.

6. On a Cache Hit: The cached data is returned instantly to the controller.

7. On a Cache Miss:

- The generate_forecast_data block is executed.

  - It checks if the address is the DUMMY_ADDRESS and returns mock data.

  - (In production) It would call get_coordinates, then @client.one_call, and finally parse_data.

  - The resulting data hash is stored in the cache and returned to the controller.

8. The ForecastsController passes the data (or nil) to the view to be rendered.