module Fastlane
  module Actions
    module SharedValues
      ONE_SIGNAL_APP_ID = :ONE_SIGNAL_APP_ID
      ONE_SIGNAL_APP_AUTH_KEY = :ONE_SIGNAL_APP_AUTH_KEY
    end

    class OnesignalAction < Action
      def self.run(params)
        require 'net/http'
        require 'uri'
        require 'base64'

        UI.message("Parameter App name: #{params[:app_name]}")
        auth_token = params[:auth_token]
        app_name = params[:app_name]
        apns_p12_password = params[:apns_p12_password]
        android_token = params[:android_token]

        payload = {}
        payload['name'] = app_name

        unless params[:apns_p12].nil?
          data = File.read(params[:apns_p12])
          apns_p12 = Base64.encode64(data)
          payload["apns_env"] = [:apns_env]
          payload["apns_p12"] = apns_p12
          # we need to have something for the p12 password, even if it's an empty string
          payload["apns_p12_password"] = apns_p12_password || ""
        end

        payload["gcm_key"] = android_token unless android_token.nil?

        # here's the actual lifting - POST to OneSignal

        json_headers = { 'Content-Type' => 'application/json', 'Authorization' => "Basic #{auth_token}" }
        uri = URI.parse('https://onesignal.com/api/v1/apps')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.post(uri.path, payload.to_json, json_headers)
        response_body = JSON.parse(response.body)

        Actions.lane_context[SharedValues::ONE_SIGNAL_APP_ID] = response_body["id"]
        Actions.lane_context[SharedValues::ONE_SIGNAL_APP_AUTH_KEY] = response_body["basic_auth_key"]

        check_response_code(response)
      end

      def self.check_response_code(response)
        case response.code.to_i
        when 200, 204
          puts "Succesfully created new OneSignal app".green
        else
          raise "Unexpected #{response.code} with response: #{response.body}".red
        end
      end

      def self.description
        "Create a new OneSignal application"
      end

      def self.details
        "You can use this action to automatically create a OneSignal application. You can also upload a .p12 with password, a GCM key, or both"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :auth_token,
                                      env_name: "ONE_SIGNAL_AUTH_KEY",
                                      description: "OneSignal Authorization Key",
                                      verify_block: proc do |value|
                                        unless value.to_s.length > 0
                                          UI.error("Please add 'ENV[\"ONE_SIGNAL_AUTH_KEY\"] = \"your token\"' to your Fastfile's `before_all` section.")
                                          raise 'No ONE_SIGNAL_AUTH_KEY given.'.red
                                        end
                                      end),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                       env_name: "ONE_SIGNAL_APP_NAME",
                                       description: "OneSignal App Name",
                                       verify_block: proc do |value|
                                         unless value.to_s.length > 0
                                           UI.error("Please add 'ENV[\"ONE_SIGNAL_APP_NAME\"] = \"Your app name\"' to your Fastfile's `before_all` section.")
                                           raise 'No ONE_SIGNAL_APP_NAME given.'.red
                                         end
                                       end),

          FastlaneCore::ConfigItem.new(key: :android_token,
                                       env_name: "ANDROID_TOKEN",
                                       description: "ANDROID GCM KEY",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_p12,
                                       env_name: "APNS_P12",
                                       description: "APNS P12 File (in .p12 format)",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_p12_password,
                                       env_name: "APNS_P12_PASSWORD",
                                       description: "APNS P12 password",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_env,
                                       env_name: "APNS_ENV",
                                       description: "APNS environment",
                                       optional: true,
                                       default_value: 'production')
        ]
      end

      def self.output
        [
          ['ONE_SIGNAL_APP_ID', 'The OneSignal app ID of the newly created app'],
          ['ONE_SIGNAL_APP_AUTH_KEY', 'The auth token for the newly created OneSignal app']
        ]
      end

      def self.return_value
      end

      def self.authors
        ["timothybarraclough", "smartshowltd"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
