# frozen_string_literal: true

require "thor"
require "commitgpt/commit_ai"

module CommitGpt
  # CommitGpt CLI
  class CLI < Thor
    default_task :aicm

    desc "aicm", "AI commits for you!"
    method_option :models, aliases: "-m", type: :boolean, desc: "List available models"
    method_option :verbose, aliases: "-v", type: :boolean, desc: "Show git diff being sent to AI"
    def aicm
      if options[:models]
        CommitGpt::CommitAi.new.list_models
      else
        CommitGpt::CommitAi.new.aicm(verbose: options[:verbose])
      end
    end
  end
end
