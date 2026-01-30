# frozen_string_literal: true

require 'httparty'
require 'net/http'
require 'uri'
require 'json'
require 'io/console'
require 'tty-prompt'
require_relative 'string'
require_relative 'config_manager'
require_relative 'diff_helpers'

# CommitGpt based on GPT-3
module CommitGpt
  # Commit AI roboter based on GPT-3
  class CommitAi
    include DiffHelpers

    attr_reader :api_key, :base_url, :model, :diff_len

    def initialize
      provider_config = ConfigManager.get_active_provider_config

      if provider_config
        @api_key = provider_config['api_key']
        @base_url = provider_config['base_url']
        @model = provider_config['model']
        @diff_len = provider_config['diff_len'] || 32_768
      else
        @api_key = nil
        @base_url = nil
        @model = nil
        @diff_len = 32_768
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

      loop do
        ai_commit_message = message(diff) || exit(1)
        action = confirm_commit(ai_commit_message)

        case action
        when :commit
          commit_command = "git commit -m \"#{ai_commit_message}\""
          puts "\n▲ Executing: #{commit_command}".yellow
          system(commit_command)
          puts "\n\n"
          puts `git log -1`
          break
        when :regenerate
          puts "\n"
          next
        when :edit
          prompt = TTY::Prompt.new
          new_message = prompt.ask('Enter your commit message:')
          if new_message && !new_message.strip.empty?
             commit_command = "git commit -m \"#{new_message}\""
             system(commit_command)
             puts "\n"
             puts `git log -1`
          else
             puts '▲ Commit aborted (empty message).'.red
          end
          break
        when :exit
          puts '▲ Exit without commit.'.yellow
          break
        end
      end
    end

    def list_models
      headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => "Ruby/#{RUBY_VERSION}"
      }
      headers['Authorization'] = "Bearer #{@api_key}" if @api_key

      begin
        response = HTTParty.get("#{@base_url}/models", headers: headers)
        models = response['data'] || []
        models.each { |m| puts m['id'] }
      rescue StandardError => e
        puts "▲ Failed to list models: #{e.message}".red
      end
    end

    def list_models
      headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => "Ruby/#{RUBY_VERSION}"
      }
      headers['Authorization'] = "Bearer #{AICM_KEY}" if AICM_KEY

      begin
        response = HTTParty.get("#{AICM_LINK}/models", headers: headers)
        models = response['data'] || []
        models.each { |m| puts m['id'] }
      rescue StandardError => e
        puts "▲ Failed to list models: #{e.message}".red
      end
    end

    private

    def confirm_commit(_message)
      prompt = TTY::Prompt.new

      begin
        prompt.select('Action:') do |menu|
          menu.choice 'Commit', :commit
          menu.choice 'Regenerate', :regenerate
          menu.choice 'Edit', :edit
          menu.choice 'Exit without commit', :exit
        end
      rescue TTY::Reader::InputInterrupt, Interrupt
        :exit
      end
    end

    def message(diff = nil)
      generate_commit(diff)
    end

    def welcome
      puts "\n▲ Welcome to AI Commits!".green

      # Check if config exists
      unless ConfigManager.config_exists?
        puts '▲ Configuration not found. Generating default config...'.yellow
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
        puts '▲ This is not a git repository'.red
        return false
      end

      true
    end

    def generate_commit(diff = '')
      messages = [
        {
          role: 'system',
          content: 'Generate a concise git commit message title in present tense that precisely describes the key changes in the following code diff. Focus on what was changed, not just file names. Provide only the title, no description or body. ' \
                   "Message language: English. Rules:\n" \
                   "- Commit message must be a maximum of 100 characters.\n" \
                   "- Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.\n" \
                   "- IMPORTANT: Do not include any explanations, introductions, or additional text. Do not wrap the commit message in quotes or any other formatting. The commit message must not exceed 100 characters. Respond with ONLY the commit message text. \n" \
                   "- Be specific: include concrete details (package names, versions, functionality) rather than generic statements. \n" \
                   '- Return ONLY the commit message, nothing else.'
        },
        {
          role: 'user',
          content: "Generate a commit message for the following git diff:\n\n#{diff}"
        }
      ]

      # Check config for disable_reasoning support (default true if not set)
      provider_config = ConfigManager.get_active_provider_config
      can_disable_reasoning = provider_config.key?('can_disable_reasoning') ? provider_config['can_disable_reasoning'] : true
      # Get configured max_tokens or default to 2000
      configured_max_tokens = provider_config['max_tokens'] || 2000

      payload = {
        model: @model,
        messages: messages,
        temperature: 0.5,
        stream: true
      }

      if can_disable_reasoning
        payload[:disable_reasoning] = true
        payload[:max_tokens] = 300
      else
        payload[:max_tokens] = configured_max_tokens
      end

      # Initial UI feedback (only on first try)
      puts '....... Generating your AI commit message ......'.gray unless defined?(@is_retrying) && @is_retrying

      full_content = ''
      full_reasoning = ''
      printed_reasoning = false
      printed_content_prefix = false
      stop_stream = false

      uri = URI("#{@base_url}/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{@api_key}" if @api_key
      request.body = payload.to_json

      begin
        http.request(request) do |response|
          if response.code != '200'
            # Parse error body
            error_body = response.read_body
            result = begin
                       JSON.parse(error_body)
            rescue StandardError
                       nil
            end

            error_msg = if result
                          result.dig('error', 'message') || result['error'] || result['message']
                        else
                          error_body
                        end

            if error_msg.nil? || error_msg.to_s.strip.empty?
              error_msg = "HTTP #{response.code}"
              error_msg += " Raw: #{error_body}" unless error_body.to_s.strip.empty?
            end

            if can_disable_reasoning && (error_msg =~ /parameter|reasoning|unsupported/i || response.code == '400')
               puts "▲ Provider does not support 'disable_reasoning'. Updating config and retrying...".yellow
               ConfigManager.update_provider(provider_config['name'], { 'can_disable_reasoning' => false })
               @is_retrying = true
               return generate_commit(diff)
            else
               puts "▲ API Error: #{error_msg}".red
               return nil
            end
          end

          # Process Streaming Response
          buffer = ''
          response.read_body do |chunk|
            break if stop_stream

            buffer += chunk
            while (line_end = buffer.index("\n"))
              line = buffer.slice!(0, line_end + 1).strip
              next if line.empty?
              next unless line.start_with?('data: ')

              data_str = line[6..]
              next if data_str == '[DONE]'

              begin
                data = JSON.parse(data_str)
                delta = data.dig('choices', 0, 'delta')
                next unless delta

                # Handle Reasoning
                reasoning_chunk = delta['reasoning_content'] || delta['reasoning']
                if reasoning_chunk && !reasoning_chunk.empty?
                  puts "\nThinking...".gray unless printed_reasoning
                  print reasoning_chunk.gray
                  full_reasoning += reasoning_chunk
                  printed_reasoning = true
                  $stdout.flush
                end

                # Handle Content
                content_chunk = delta['content']
                if content_chunk && !content_chunk.empty?
                  if printed_reasoning && !printed_content_prefix
                    puts '' # Newline after reasoning block
                  end

                  unless printed_content_prefix
                    print "\n▲ Commit message: git commit -am \"".green
                    printed_content_prefix = true
                  end

                  # Prevent infinite loops/repetitive garbage
                  if full_content.length + content_chunk.length > 300
                    stop_stream = true
                    break
                  end

                  print content_chunk.green
                  full_content += content_chunk
                  $stdout.flush
                end

                # Handle Usage (some providers send usage at the end)
                @last_usage = data['usage'] if data['usage']
              rescue JSON::ParserError
                # Partial JSON, wait for more data
              end
            end
          end
        end
      rescue StandardError => e
        puts "▲ Error: #{e.message}".red
        return nil
      end

      # Close the quote
      puts '"'.green if printed_content_prefix

      # Post-processing Logic (Retry if empty content)
      if (full_content.nil? || full_content.strip.empty?) && (full_reasoning && !full_reasoning.strip.empty?)
          if can_disable_reasoning
              puts "\n▲ Model returned reasoning despite 'disable_reasoning: true'. Updating config and retrying...".yellow
              ConfigManager.update_provider(provider_config['name'], { 'can_disable_reasoning' => false })
              @is_retrying = true
              return generate_commit(diff)
          else
              puts "\n▲ Model output truncated (Reasoning consumed all #{configured_max_tokens} tokens).".red
              prompt = TTY::Prompt.new
              choice = prompt.select('Choose an action:') do |menu|
                menu.choice "Double max_tokens to #{configured_max_tokens * 2}", :double
                menu.choice 'Set custom max_tokens...', :custom
                menu.choice 'Abort', :abort
              end

              new_max = case choice
                        when :double
                          configured_max_tokens * 2
                        when :custom
                          prompt.ask('Enter new max_tokens:', convert: :int)
                        when :abort
                          return nil
                        end

              if new_max
                 puts "▲ Updating max_tokens to #{new_max} and retrying...".yellow
                 ConfigManager.update_provider(provider_config['name'], { 'max_tokens' => new_max })
                 @is_retrying = true
                 return generate_commit(diff)
              end
              return nil
          end
      end

      if full_content.empty? && full_reasoning.empty?
        puts '▲ No response from AI.'.red
        return nil
      end

      # Print usage info if available (saved from stream or approximated)
      if defined?(@last_usage) && @last_usage
        puts "\n...... Tokens: #{@last_usage['total_tokens']} (Prompt: #{@last_usage['prompt_tokens']}, Completion: #{@last_usage['completion_tokens']})\n\n".gray
        @last_usage = nil
      end

      # Reset retrying flag
      @is_retrying = false

      # Take only the first non-empty line to avoid repetition or multi-line garbage
      first_line = full_content.split("\n").map(&:strip).reject(&:empty?).first
      first_line&.gsub(/\A["']|["']\z/, '') || ''
    end
  end
end
