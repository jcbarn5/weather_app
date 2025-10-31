Geocoder.configure(
  lookup: :google,
  use_https: true,
  api_key: Rails.application.credentials.geocoder_api_key,
  timeout: 5
)