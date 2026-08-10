# frozen_string_literal: true

require 'tty-prompt'
require 'httparty'
require 'timeout'
require_relative 'config_manager'
require_relative 'provider_presets'
require_relative 'string'

module CommitGpt
  # Interactive setup wizard for configuring AI providers
  class SetupWizard
    # Diff bytes per context token. Code and CJK pack more bytes into a token
    # than English prose, so this stays deliberately conservative.
    DIFF_BYTES_PER_TOKEN = 2

    # Ceiling for the suggested diff length. Past this a single request gets
    # slow and one commit message stops describing the change usefully, so
    # chunked mode is the better answer than a bigger window.
    MAX_SUGGESTED_DIFF_LEN = 131_072

    # Used when the model's context window is unknown
    FALLBACK_DIFF_LEN = 32_768

    def initialize
      @prompt = TTY::Prompt.new
    end

    # Main entry point for setup
    def run
      ConfigManager.ensure_config_dir
      ConfigManager.generate_default_configs unless ConfigManager.config_exists?

      prompt_model_fetch_timeout
      provider_choice = select_provider
      configure_provider(provider_choice)
    end

    # Switch to a different configured provider
    def switch_provider
      configured = ConfigManager.configured_providers

      if configured.empty?
        puts "✖ No providers configured. Please run 'aicm setup' first.".red
        return
      end

      choices = configured.map do |p|
        preset = PROVIDER_PRESETS.find { |pr| pr[:value] == p['name'] }
        { name: preset ? preset[:label] : p['name'], value: p['name'] }
      end

      selected = @prompt.select('Choose your provider:', choices)

      # Get current config for this provider
      config = ConfigManager.load_config
      provider = config['providers'].find { |p| p['name'] == selected }

      # Fetch models and let user select
      models = fetch_models_with_timeout(provider['base_url'], provider['api_key'], preset_models(selected))
      return if models.nil?

      model = select_model(models, provider['model'])

      # Prompt for diff length
      diff_len = prompt_diff_len(default_diff_len(selected, model, provider['diff_len']))

      # Update config
      ConfigManager.update_provider(selected, { 'model' => model, 'diff_len' => diff_len })
      reset_provider_inference_params(selected)
      ConfigManager.set_active_provider(selected)

      preset = PROVIDER_PRESETS.find { |pr| pr[:value] == selected }
      provider_label = preset ? preset[:label] : selected

      puts "\nModel selected: #{model}".green
      puts "Setup complete ✅  You're now using #{provider_label}.".green
    end

    # Change model for the active provider
    def change_model
      provider_config = ConfigManager.get_active_provider_config

      if provider_config.nil? || provider_config['api_key'].nil? || provider_config['api_key'].empty?
        puts "✖ No active provider configured. Please run 'aicm setup'.".red
        return
      end

      # Fetch models and let user select
      models = fetch_models_with_timeout(provider_config['base_url'], provider_config['api_key'],
                                         preset_models(provider_config['name']))
      return if models.nil?

      model = select_model(models, provider_config['model'])

      # Update config
      ConfigManager.update_provider(provider_config['name'], { 'model' => model })
      reset_provider_inference_params(provider_config['name'])

      puts "\nModel selected: #{model}".green
    end

    # Choose commit message format
    def choose_format
      prompt = TTY::Prompt.new

      puts "\n→ Choose git commit message format:\n".green

      format = prompt.select('Select format:') do |menu|
        menu.choice 'Simple - Concise commit message', 'simple'
        menu.choice 'Conventional - Follow Conventional Commits specification', 'conventional'
        menu.choice 'Gitmoji - Use Gitmoji emoji standard', 'gitmoji'
      end

      ConfigManager.set_commit_format(format)
      puts "\n✔ Commit format set to: #{format}".green
    end

    # Choose how much the commit message says
    def choose_detail
      puts "\n→ Choose git commit message detail level:\n".green

      detail = @prompt.select('Select detail level:', default: default_detail_index) do |menu|
        menu.choice 'Concise - Subject line only', 'concise'
        menu.choice 'Detailed - Subject line, explanatory paragraph, and bullet list of changes', 'detailed'
      end

      ConfigManager.set_commit_detail(detail)
      puts "\n✔ Commit detail set to: #{detail}".green
    end

    private

    # Menu position of the currently configured detail level (1-based)
    def default_detail_index
      ConfigManager::COMMIT_DETAILS.index(ConfigManager.get_commit_detail).to_i + 1
    end

    # Select provider from list
    def select_provider
      config = ConfigManager.load_config
      configured = config ? (config['providers'] || []) : []

      choices = PROVIDER_PRESETS.map do |preset|
        # Check if this provider already has an API key
        provider_config = configured.find { |p| p['name'] == preset[:value] }
        has_key = provider_config && provider_config['api_key'] && !provider_config['api_key'].empty?

        label = preset[:label]
        label = "✅ #{label}" if has_key
        label = "#{label} (recommended)" if preset[:value] == 'cerebras'
        label = "#{label} (local)" if %w[ollama llamacpp lmstudio llamafile].include?(preset[:value])

        { name: label, value: preset[:value] }
      end

      choices << { name: 'Custom (OpenAI-compatible)', value: 'custom' }

      @prompt.select('Choose your AI provider:', choices, per_page: 15)
    end

    # Configure selected provider
    def configure_provider(provider_name)
      if provider_name == 'custom'
        configure_custom_provider
        return
      end

      preset = PROVIDER_PRESETS.find { |p| p[:value] == provider_name }
      base_url = preset[:base_url]
      provider_label = preset[:label]

      # Get existing API key if any
      config = ConfigManager.load_config
      existing_provider = config['providers'].find { |p| p['name'] == provider_name } if config

      # Prompt for API key
      api_key = prompt_api_key(provider_label, existing_provider&.dig('api_key'))
      return if api_key.nil? # User cancelled

      # Fetch models with timeout
      models = fetch_models_with_timeout(base_url, api_key, preset_models(provider_name))
      return if models.nil?

      # Let user select model
      model = select_model(models, existing_provider&.dig('model'))

      # Prompt for diff length
      diff_len = prompt_diff_len(default_diff_len(provider_name, model, existing_provider&.dig('diff_len')))

      # Save configuration
      ConfigManager.update_provider(
        provider_name,
        { 'model' => model, 'diff_len' => diff_len },
        { 'api_key' => api_key }
      )
      ConfigManager.set_active_provider(provider_name)

      puts "\nModel selected: #{model}".green
      puts "✅ Setup complete! You're now using #{provider_label}.".green
    end

    # Configure custom provider
    def configure_custom_provider
      provider_name = @prompt.ask('Enter provider name:') do |q|
        q.required true
        q.modify :strip, :down
      end

      base_url = @prompt.ask('Enter base URL:') do |q|
        q.required true
        q.default 'http://localhost:8080/v1'
      end

      api_key = @prompt.mask('Enter your API key (optional):') { |q| q.echo false }.to_s

      # Fetch models
      models = fetch_models_with_timeout(base_url, api_key)
      return if models.nil?

      model = select_model(models)
      diff_len = prompt_diff_len(FALLBACK_DIFF_LEN)

      # Add to presets dynamically (just for this session)
      # Save to config
      config = ConfigManager.load_config || { 'providers' => [], 'active_provider' => '' }

      # Add or update provider in main config
      existing = config['providers'].find { |p| p['name'] == provider_name }
      if existing
        existing.merge!({ 'model' => model, 'diff_len' => diff_len, 'base_url' => base_url })
      else
        config['providers'] << {
          'name' => provider_name,
          'model' => model,
          'diff_len' => diff_len,
          'base_url' => base_url
        }
      end
      config['active_provider'] = provider_name
      ConfigManager.save_main_config(config)

      # Update local config
      local_config = if File.exist?(ConfigManager.local_config_path)
                       YAML.load_file(ConfigManager.local_config_path)
                     else
                       { 'providers' => [] }
                     end

      local_existing = local_config['providers'].find { |p| p['name'] == provider_name }
      if local_existing
        local_existing['api_key'] = api_key
      else
        local_config['providers'] << { 'name' => provider_name, 'api_key' => api_key }
      end
      ConfigManager.save_local_config(local_config)

      puts "\nModel selected: #{model}".green
      puts "✅ Setup complete! You're now using #{provider_name}.".green
    end

    # Prompt for API key
    def prompt_api_key(_provider_name, existing_key)
      has_existing = existing_key && !existing_key.empty?

      message = if has_existing
                  'Enter your API key (press Enter to keep existing):'
                else
                  'Enter your API key:'
                end

      # mask returns nil, not '', when the input is empty
      key = @prompt.mask(message) { |q| q.echo false }.to_s

      # If user pressed Enter and there's an existing key, use it
      key.empty? && has_existing ? existing_key : key
    end

    # Ask how long to wait when fetching the model list, and persist it
    def prompt_model_fetch_timeout
      current = ConfigManager.get_model_fetch_timeout

      seconds = @prompt.ask('Set the timeout (seconds) for fetching the model list:') do |q|
        q.default current.to_s
        q.convert :int
        q.validate ->(input) { input.to_i.positive? }
        q.messages[:valid?] = 'Timeout must be a positive number of seconds'
      end

      seconds = current unless seconds.is_a?(Integer) && seconds.positive?
      ConfigManager.set_model_fetch_timeout(seconds)
      seconds
    end

    # Built-in models a preset declares, as { model => context tokens }
    def preset_model_table(provider_name)
      models = PROVIDER_PRESETS.find { |p| p[:value] == provider_name }&.dig(:models)
      models unless models.nil? || models.empty?
    end

    # Built-in model list for a preset, if it declares one
    def preset_models(provider_name)
      preset_model_table(provider_name)&.keys
    end

    # Context window of a built-in model, in tokens
    def model_context_tokens(provider_name, model)
      preset_model_table(provider_name)&.dig(model)
    end

    # Default diff length for a model, derived from its context window when
    # known, and reported so the number is not a mystery. Numbers are printed
    # undelimited because they get typed straight into the next prompt.
    def default_diff_len(provider_name, model, existing)
      context_tokens = model_context_tokens(provider_name, model)
      return existing || FALLBACK_DIFF_LEN if context_tokens.nil?

      fits = context_tokens * DIFF_BYTES_PER_TOKEN
      suggested = [fits, MAX_SUGGESTED_DIFF_LEN].min
      capped = ' (capped; larger diffs use chunked mode)' if suggested < fits

      puts "\n#{model} context window: #{context_tokens} tokens (~#{fits} bytes of diff)".gray
      puts "  Suggested max diff length: #{suggested} bytes#{capped}".gray

      # Only a value the user actually chose outranks the suggestion
      customized = existing && existing != FALLBACK_DIFF_LEN
      customized ? existing : suggested
    end

    # Fetch models from provider with timeout.
    # A preset that declares :models has no usable /models endpoint, so its
    # built-in list is offered directly and no request is made.
    def fetch_models_with_timeout(base_url, api_key, builtin_models = nil)
      if builtin_models
        puts 'Using the built-in model list (this provider does not expose /models).'.gray
        return builtin_models
      end

      timeout = ConfigManager.get_model_fetch_timeout
      puts 'Fetching available models...'.gray

      models = nil
      failure = nil

      begin
        Timeout.timeout(timeout) do
          headers = {
            'Content-Type' => 'application/json',
            'User-Agent' => "Ruby/#{RUBY_VERSION}"
          }
          headers['Authorization'] = "Bearer #{api_key}" if api_key && !api_key.empty?

          response = HTTParty.get("#{base_url}/models", headers: headers)

          if response.code == 200
            models = (response['data'] || []).map { |m| m['id'] }.compact.sort
          else
            failure = "Failed to fetch models: HTTP #{response.code}"
          end
        end
      rescue Timeout::Error
        failure = "Connection timeout (#{timeout}s). Please check your network, base_url, and api_key."
      rescue StandardError => e
        failure = "Error fetching models: #{e.message}"
      end

      failure ||= 'No models found. Please check your configuration.' if models.nil? || models.empty?
      return models if failure.nil?

      puts "✖ #{failure}".red
      puts "  Run 'aicm setup' again to raise the timeout.".gray if failure.start_with?('Connection timeout')
      exit(0)
    end

    # Let user select a model
    def select_model(models, current_model = nil)
      choices = models.map { |m| { name: m, value: m } }
      choices << { name: 'Custom model name...', value: :custom }

      # Set default to current model if it exists
      default_index = if current_model && models.include?(current_model)
                        models.index(current_model) + 1 # +1 for 1-based index
                      else
                        1
                      end

      selected = @prompt.select('Choose your model:', choices, per_page: 15, default: default_index)

      if selected == :custom
        @prompt.ask('Enter custom model name:') do |q|
          q.required true
          q.modify :strip
        end
      else
        selected
      end
    end

    # Prompt for diff length
    def prompt_diff_len(default = FALLBACK_DIFF_LEN)
      answer = @prompt.ask('Set the maximum diff length (Bytes) for generating commit message:') do |q|
        q.default default.to_s
        q.convert :int
      end

      answer || default
    end

    def reset_provider_inference_params(provider_name)
      config = YAML.load_file(ConfigManager.main_config_path)
      return unless config && config['providers']

      provider = config['providers'].find { |p| p['name'] == provider_name }
      if provider
        provider.delete('can_disable_reasoning')
        provider.delete('max_tokens')
        ConfigManager.save_main_config(config)
      end
    end
  end
end
