# frozen_string_literal: true

require "httparty"
require "json"
require "io/console"
require_relative "string"

# CommitGpt based on GPT-3
module CommitGpt
  # Commit AI roboter based on GPT-3
  class CommitAi
    OPENAI_API_KEY = ENV.fetch("OPENAI_API_KEY", nil)
    def aicm
      exit(1) unless welcome
      diff = git_diff || exit(1)
      ai_commit_message = message(diff) || exit(1)
      puts `git commit -m "#{ai_commit_message}" && echo && echo && git log -1 && echo` if confirmed
    end

    private

    def confirmed
      puts "▲ Do you want to commit this message? [y/n]".magenta

      use_commit_message = nil
      use_commit_message = $stdin.getch.downcase until use_commit_message =~ /\A[yn]\z/i

      puts "\n▲ Commit message has not been commited.\n".red if use_commit_message == "n"

      use_commit_message == "y"
    end

    def message(diff = nil)
      prompt = "I want you to act like a git commit message writer. I will input a git diff and your job is to convert it into a useful " \
               "commit message. Do not preface the commit with anything, use the present tense, return a complete sentence, " \
               "and do not repeat yourself: #{diff}"

      puts "▲    Generating your AI commit message...\n".gray
      ai_commit_message = generate_commit(prompt)
      return nil if ai_commit_message.nil?

      puts "#{"▲ Commit message: ".green}git commit -am \"#{ai_commit_message}\"\n\n"
      ai_commit_message
    end

    def git_diff
      diff = `git diff --cached . ":(exclude)Gemfile.lock" ":(exclude)package-lock.json" ":(exclude)yarn.lock" ":(exclude)pnpm-lock.yaml"`.chomp

      if diff.empty?
        puts "▲ No staged changes found. Make sure there are changes and run `git add .`".red
        return nil
      end

      # Accounting for GPT-3's input req of 4k tokens (approx 8k chars)
      if diff.length > 8000
        puts "▲ The diff is too large to write a commit message.".red
        return nil
      end

      diff
    end

    def welcome
      puts "\n▲  Welcome to AI Commits!".green

      if OPENAI_API_KEY.nil?
        puts "▲ Please save your OpenAI API key as an env variable by doing 'export OPENAI_API_KEY=YOUR_API_KEY'".red
        return false
      end

      begin
        `git rev-parse --is-inside-work-tree`
      rescue StandardError
        puts "▲ This is not a git repository".red
        return false
      end

      true
    end

    def generate_commit(prompt = "")
      payload = {
        model: "text-davinci-003", prompt: prompt, temperature: 0.7, top_p: 1,
        frequency_penalty: 0, presence_penalty: 0, max_tokens: 200, stream: false, n: 1
      }

      begin
        response = HTTParty.post("https://api.openai.com/v1/completions",
                                 headers: { "Authorization" => "Bearer #{OPENAI_API_KEY}",
                                            "Content-Type" => "application/json", "User-Agent" => "Ruby/#{RUBY_VERSION}" },
                                 body: payload.to_json)

        puts response.inspect

        ai_commit = response["choices"][0]["text"]
      rescue StandardError
        puts "▲ There was an error with the OpenAI API. Please try again later.".red
        return nil
      end

      ai_commit.gsub(/(\r\n|\n|\r)/, "")
    end
  end
end
