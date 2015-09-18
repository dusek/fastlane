module Gym
  # Responsible for building the fully working xcodebuild command
  class PackageCommandGeneratorXcode7
    class << self
      def generate
        if Gym.config[:provisioning_profile_path]
          Helper.log.info "You're using Xcode 7, the `provisioning_profile_path` value will be ignored".yellow
          Helper.log.info "Please follow the Code Signing Guide: https://github.com/KrauseFx/fastlane/blob/master/docs/CodeSigning.md".yellow
        end

        parts = ["/usr/bin/xcrun xcodebuild -exportArchive"]
        parts += options
        parts += pipe

        File.write(config_path, config_content) # overwrite everytime. Could be optimized

        parts
      end

      def options
        options = []

        options << "-exportOptionsPlist '#{config_path}'"
        options << "-archivePath '#{BuildCommandGenerator.archive_path}'"
        options << "-exportPath '#{temporary_output_path}'"

        options
      end

      def pipe
        [""]
      end

      # We export the ipa into this directory, as we can't specify the ipa file directly
      def temporary_output_path
        @temporary_output_path ||= File.join("/tmp", Time.now.to_i.to_s)
      end

      def ipa_path
        unless @ipa_path
          path = Dir[File.join(temporary_output_path, "*.ipa")].last

          @ipa_path = File.join(temporary_output_path, "#{Gym.config[:output_name]}.ipa")
          FileUtils.mv(path, @ipa_path)
        end
        @ipa_path
      end

      # The path the the dsym file for this app. Might be nil
      def dsym_path
        Dir[BuildCommandGenerator.archive_path + "/**/*.app.dSYM"].last
      end

      # The path the config file we use to sign our app
      def config_path
        @config_path ||= "/tmp/gym_config_#{Time.now.to_i}.plist"
        return @config_path
      end

      private

      def config_content
        require 'plist'
        symbols = (Gym.config[:include_symbols] ? true : false)
        bitcode = (Gym.config[:include_bitcode] ? true : false)

        {
          method: 'app-store',
          uploadSymbols: symbols,
          uploadBitcode: bitcode
        }.to_plist
      end
    end
  end
end