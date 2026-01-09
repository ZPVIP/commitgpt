# frozen_string_literal: true

require "httparty"
require "json"
require "io/console"
require_relative "string"

# CommitGpt based on GPT-3
module CommitGpt
  # Commit AI roboter based on GPT-3
  class CommitAi
    AICM_KEY = ENV.fetch("AICM_KEY", nil)
    AICM_LINK = ENV.fetch("AICM_LINK", "https://api.openai.com/v1")
    AICM_DIFF_LEN = ENV.fetch("AICM_DIFF_LEN", "32768").to_i
    AICM_MODEL = ENV.fetch("AICM_MODEL", "gpt-4o-mini")

    def aicm(verbose: false)
      exit(1) unless welcome
      diff = git_diff || exit(1)
      if verbose
        puts "▲ Git diff (#{diff.length} chars):".cyan
        puts diff
        puts "\n"
      end
      ai_commit_message = message(diff) || exit(1)
      puts `git commit -m "#{ai_commit_message}" && echo && echo && git log -1 && echo` if confirmed
    end

    def list_models
      headers = {
        "Content-Type" => "application/json",
        "User-Agent" => "Ruby/#{RUBY_VERSION}"
      }
      headers["Authorization"] = "Bearer #{AICM_KEY}" if AICM_KEY

      begin
        response = HTTParty.get("#{AICM_LINK}/models", headers: headers)
        models = response["data"] || []
        models.each { |m| puts m["id"] }
      rescue StandardError => e
        puts "▲ Failed to list models: #{e.message}".red
      end
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
      puts "▲   Generating your AI commit message...\n".gray
      ai_commit_message = generate_commit(diff)
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

      if diff.length > AICM_DIFF_LEN
        puts "▲ The diff is too large (#{diff.length} chars, max #{AICM_DIFF_LEN}). Set AICM_DIFF_LEN to increase limit.".red
        return nil
      end

      diff
    end

    def welcome
      puts "\n▲ Welcome to AI Commits!".green

      if AICM_KEY.nil? && AICM_LINK == "https://api.openai.com/v1"
        puts "▲ Please save your API key as an env variable by doing 'export AICM_KEY=YOUR_API_KEY'".red
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

    def generate_commit(diff = "")
      messages = [
        {
          role: "system",
          content: "Generate a concise git commit message title in present tense that precisely describes the key changes in the following code diff. Focus on what was changed, not just file names. Provide only the title, no description or body. " \
                   "Message language: English. Rules:\n" \
                   "- Use present tense (e.g., 'Add feature' not 'Added feature')\n" \
                   "- Commit message must be a maximum of 100 characters.\n" \
                   "- Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.\n" \
                   "- IMPORTANT: Do not include any explanations, introductions, or additional text. Do not wrap the commit message in quotes or any other formatting. The commit message must not exceed 100 characters. Respond with ONLY the commit message text. \n" \
                   "- Be specific: include concrete details (package names, versions, functionality) rather than generic statements. \n" \
                   "- Return ONLY the commit message, nothing else."
        },
        {
          role: "user",
          content: "Generate a commit message for the following git diff:\n\n#{diff}"
        }
      ]

      payload = {
        model: AICM_MODEL,
        messages: messages,
        temperature: 0.7,
        max_tokens: 200
      }

      begin
        headers = {
          "Content-Type" => "application/json",
          "User-Agent" => "Ruby/#{RUBY_VERSION}"
        }
        headers["Authorization"] = "Bearer #{AICM_KEY}" if AICM_KEY

        response = HTTParty.post("#{AICM_LINK}/chat/completions",
                                 headers: headers,
                                 body: payload.to_json)

        ai_commit = response["choices"][0]["message"]["content"]
      rescue StandardError
        puts "▲ There was an error with the OpenAI API. Please try again later.".red
        return nil
      end

      ai_commit.gsub(/(\r\n|\n|\r)/, "").gsub(/\A["']|["']\z/, "")
    end
  end
end
