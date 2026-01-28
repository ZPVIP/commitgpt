# frozen_string_literal: true

require "httparty"
require "json"
require "io/console"
require "tty-prompt"
require_relative "string"
require_relative "config_manager"

# CommitGpt based on GPT-3
module CommitGpt
  # Commit AI roboter based on GPT-3
  class CommitAi
    attr_reader :api_key, :base_url, :model, :diff_len

    def initialize
      provider_config = ConfigManager.get_active_provider_config
      
      if provider_config
        @api_key = provider_config["api_key"]
        @base_url = provider_config["base_url"]
        @model = provider_config["model"]
        @diff_len = provider_config["diff_len"] || 32768
      else
        @api_key = nil
        @base_url = nil
        @model = nil
        @diff_len = 32768
      end
    end

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
      headers["Authorization"] = "Bearer #{@api_key}" if @api_key

      begin
        response = HTTParty.get("#{@base_url}/models", headers: headers)
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

      if diff.length > @diff_len
        choice = prompt_diff_handling(diff.length, @diff_len)
        case choice
        when :truncate
          puts "▲ Truncating diff to #{@diff_len} chars...".yellow
          diff = diff[0...@diff_len]
        when :unlimited
          puts "▲ Using full diff (#{diff.length} chars)...".yellow
        when :exit
          return nil
        end
      end

      diff
    end

    def prompt_diff_handling(current_len, max_len)
      puts "▲ The diff is too large (#{current_len} chars, max #{max_len}).".yellow
      prompt = TTY::Prompt.new
      prompt.select("Choose an option:") do |menu|
        menu.choice "Use first #{max_len} characters to generate commit message", :truncate
        menu.choice "Use unlimited characters (may fail or be slow)", :unlimited
        menu.choice "Exit", :exit
      end
    end

    def welcome
      puts "\n▲ Welcome to AI Commits!".green

      # Check if config exists
      unless ConfigManager.config_exists?
        puts "▲ Configuration not found. Generating default config...".yellow
        ConfigManager.generate_default_configs
        puts "▲ Please run 'aicm setup' to configure your provider.".red
        return false
      end

      # Check if active provider is configured
      if @api_key.nil? || @api_key.empty?
        puts "▲ No active provider configured. Please run 'aicm setup'.".red
        return false
      end

      if @model.nil? || @model.empty?
        puts "▲ No model selected. Please run 'aicm setup'.".red
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
        model: @model,
        messages: messages,
        temperature: 0.7,
        max_tokens: 300,
        disable_reasoning: true
      }

      begin
        headers = {
          "Content-Type" => "application/json",
          "User-Agent" => "Ruby/#{RUBY_VERSION}"
        }
        headers["Authorization"] = "Bearer #{@api_key}" if @api_key

        response = HTTParty.post("#{@base_url}/chat/completions",
                                 headers: headers,
                                 body: payload.to_json)

        # Check for API error response
        if response["error"]
          puts "▲ API Error: #{response['error']['message']}".red
          return nil
        end

        message = response.dig("choices", 0, "message")
        # Some models (like zai-glm) use 'reasoning' instead of 'content'
        ai_commit = message&.dig("content") || message&.dig("reasoning")
        if ai_commit.nil?
          puts "▲ Unexpected API response format:".red
          puts response.inspect
          return nil
        end
      rescue StandardError => e
        puts "▲ Error: #{e.message}".red
        return nil
      end

      ai_commit.gsub(/(\r\n|\n|\r)/, "").gsub(/\A["']|["']\z/, "")
    end
  end
end
