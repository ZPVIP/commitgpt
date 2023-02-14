# frozen_string_literal: true

require "thor"
require "commitgpt/commit_ai"

module CommitGpt
  # CommitGpt CLI
  class CLI < Thor
    default_task :aicm

    desc "aicm", "AI commits for you!"
    def aicm
      CommitGpt::CommitAi.new.aicm
    end
  end
end
