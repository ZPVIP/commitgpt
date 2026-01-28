# frozen_string_literal: true

require "yaml"
require "fileutils"
require_relative "provider_presets"
require_relative "string"

module CommitGpt
  # Manages configuration files for CommitGPT
  class ConfigManager
    class << self
      # Get the config directory path
      def config_dir
        File.expand_path("~/.config/commitgpt")
      end

      # Get main config file path
      def main_config_path
        File.join(config_dir, "config.yml")
      end

      # Get local config file path
      def local_config_path
        File.join(config_dir, "config.local.yml")
      end

      # Ensure config directory exists
      def ensure_config_dir
        FileUtils.mkdir_p(config_dir) unless Dir.exist?(config_dir)
      end

      # Check if config files exist
      def config_exists?
        File.exist?(main_config_path)
      end

      # Load and merge configuration files
      def load_config
        return nil unless config_exists?

        main_config = YAML.load_file(main_config_path) || {}
        local_config = File.exist?(local_config_path) ? YAML.load_file(local_config_path) : {}

        merge_configs(main_config, local_config)
      end

      # Get active provider configuration
      def get_active_provider_config
        config = load_config
        return nil if config.nil? || config["active_provider"].nil?

        active_provider = config["active_provider"]
        providers = config["providers"] || []

        providers.find { |p| p["name"] == active_provider }
      end

      # Save main config
      def save_main_config(config)
        ensure_config_dir
        File.write(main_config_path, config.to_yaml)
      end

      # Save local config
      def save_local_config(config)
        ensure_config_dir
        File.write(local_config_path, config.to_yaml)
      end

      # Generate default configuration files
      def generate_default_configs
        ensure_config_dir

        # Generate main config with all providers but empty models
        providers = PROVIDER_PRESETS.map do |preset|
          {
            "name" => preset[:value],
            "model" => "",
            "diff_len" => 32768,
            "base_url" => preset[:base_url]
          }
        end

        main_config = {
          "providers" => providers,
          "active_provider" => ""
        }

        # Generate local config with empty API keys
        local_providers = PROVIDER_PRESETS.map do |preset|
          {
            "name" => preset[:value],
            "api_key" => ""
          }
        end

        local_config = {
          "providers" => local_providers
        }

        save_main_config(main_config)
        save_local_config(local_config)

        # Remind user to add config.local.yml to .gitignore
        puts "▲ Generated default configuration files.".green
        puts "▲ Remember to add ~/.config/commitgpt/config.local.yml to your .gitignore".yellow
      end

      # Get list of configured providers (with API keys)
      def configured_providers
        config = load_config
        return [] if config.nil?

        providers = config["providers"] || []
        providers.select { |p| p["api_key"] && !p["api_key"].empty? }
      end

      # Update provider configuration
      def update_provider(provider_name, main_attrs = {}, local_attrs = {})
        # Update main config
        main_config = YAML.load_file(main_config_path)
        provider = main_config["providers"].find { |p| p["name"] == provider_name }
        provider&.merge!(main_attrs)
        save_main_config(main_config)

        # Update local config
        local_config = File.exist?(local_config_path) ? YAML.load_file(local_config_path) : { "providers" => [] }
        local_provider = local_config["providers"].find { |p| p["name"] == provider_name }
        if local_provider
          local_provider.merge!(local_attrs)
        else
          local_config["providers"] << { "name" => provider_name }.merge(local_attrs)
        end
        save_local_config(local_config)
      end

      # Set active provider
      def set_active_provider(provider_name)
        main_config = YAML.load_file(main_config_path)
        main_config["active_provider"] = provider_name
        save_main_config(main_config)
      end

      private

      # Merge main config with local config (local overrides main)
      def merge_configs(main_config, local_config)
        result = main_config.dup

        # Merge provider-specific settings
        main_providers = main_config["providers"] || []
        local_providers = local_config["providers"] || []

        merged_providers = main_providers.map do |main_provider|
          local_provider = local_providers.find { |lp| lp["name"] == main_provider["name"] }
          local_provider ? main_provider.merge(local_provider) : main_provider
        end

        result["providers"] = merged_providers
        result
      end
    end
  end
end
