# frozen_string_literal: true

require "thor"
require "commitgpt/commit_ai"
require "commitgpt/setup_wizard"

module CommitGpt
  # CommitGpt CLI
  class CLI < Thor
    default_task :aicm

    desc "aicm", "AI commits for you!"
    method_option :models, aliases: "-m", type: :boolean, desc: "List available models"
    method_option :verbose, aliases: "-v", type: :boolean, desc: "Show git diff being sent to AI"
    method_option :provider, aliases: "-p", type: :boolean, desc: "Switch active provider"
    def aicm
      if options[:provider]
        CommitGpt::SetupWizard.new.switch_provider
      elsif options[:models]
        CommitGpt::CommitAi.new.list_models
      else
        CommitGpt::CommitAi.new.aicm(verbose: options[:verbose])
      end
    end

    desc "setup", "Configure AI provider and settings"
    def setup
      CommitGpt::SetupWizard.new.run
    end
  end
end
