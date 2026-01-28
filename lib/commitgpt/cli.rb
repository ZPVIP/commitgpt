# frozen_string_literal: true

require 'thor'
require 'commitgpt/commit_ai'
require 'commitgpt/setup_wizard'

module CommitGpt
  # CommitGpt CLI
  class CLI < Thor
    default_task :generate

    desc 'generate', 'AI commits for you!'
    method_option :models, aliases: '-m', type: :boolean, desc: 'List/Select available models'
    method_option :verbose, aliases: '-v', type: :boolean, desc: 'Show git diff being sent to AI'
    method_option :provider, aliases: '-p', type: :boolean, desc: 'Switch active provider'
    def generate
      if options[:provider]
        CommitGpt::SetupWizard.new.switch_provider
      elsif options[:models]
        CommitGpt::SetupWizard.new.change_model
      else
        CommitGpt::CommitAi.new.aicm(verbose: options[:verbose])
      end
    end

    desc 'setup', 'Configure AI provider and settings'
    def setup
      CommitGpt::SetupWizard.new.run
    end

    # Custom help message
    def self.help(shell, _subcommand = false)
      shell.say 'Usage:'
      shell.say '  aicm                     # Generate AI commit message (Default)'
      shell.say '  aicm setup               # Configure AI provider and settings'
      shell.say '  aicm help [COMMAND]      # Describe available commands'
      shell.say ''
      shell.say 'Options:'
      shell.say '  -m, --models             # Interactive model selection'
      shell.say '  -p, --provider           # Switch active provider'
      shell.say '  -v, --verbose            # Show git diff being sent to AI'
      shell.say ''

      # Show current configuration
      begin
        require 'commitgpt/config_manager'
        require 'commitgpt/string'
        config = CommitGpt::ConfigManager.get_active_provider_config
        if config
          require 'commitgpt/version'
          shell.say "CommitGPT v#{CommitGpt::VERSION}"
          shell.say "Bin Path: #{File.realpath($PROGRAM_NAME)}".gray
          shell.say ''

          shell.say 'Current Configuration:'
          shell.say "  Provider:  #{config['name'].green}"
          shell.say "  Model:     #{config['model'].cyan}"
          shell.say "  Base URL:  #{config['base_url']}"
          shell.say "  Diff Len:  #{config['diff_len']}"
          shell.say ''
        end
      rescue StandardError
        # Ignore errors during help display if config is missing/invalid
      end
    end
  end
end
