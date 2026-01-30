# frozen_string_literal: true

module CommitGpt
  # Helper methods for handling git diffs
  # rubocop:disable Metrics/ModuleLength
  module DiffHelpers
    # Lock files to exclude from diff but detect changes
    LOCK_FILES = %w[Gemfile.lock package-lock.json yarn.lock pnpm-lock.yaml].freeze

    def git_diff
      exclusions = LOCK_FILES.map { |f| "\":(exclude)#{f}\"" }.join(' ')
      diff_cached = `git diff --cached . #{exclusions}`.chomp
      diff_unstaged = `git diff . #{exclusions}`.chomp

      # Detect lock file changes and build summary
      @lock_file_summary = detect_lock_file_changes

      if !diff_unstaged.empty?
        if diff_cached.empty?
          # Scenario: Only unstaged changes
          choice = prompt_no_staged_changes
          case choice
          when :add_all
            puts '▲ Running git add .'.yellow
            system('git add .')
            diff_cached = `git diff --cached . #{exclusions}`.chomp
            if diff_cached.empty?
              puts '▲ Still no changes to commit.'.red
              return nil
            end
          when :exit
            return nil
          end
        else
          # Scenario: Mixed state (some staged, some not)
          puts '▲ You have both staged and unstaged changes:'.yellow

          staged_files = `git diff --cached --name-status . #{exclusions}`.chomp
          unstaged_files = `git diff --name-status . #{exclusions}`.chomp

          puts "\n  #{'Staged changes:'.green}"
          puts staged_files.gsub(/^/, '    ')

          puts "\n  #{'Unstaged changes:'.red}"
          puts unstaged_files.gsub(/^/, '    ')
          puts ''

          prompt = TTY::Prompt.new
          choice = prompt.select('How to proceed?') do |menu|
            menu.choice 'Include unstaged changes (git add .)', :add_all
            menu.choice 'Use staged changes only', :staged_only
            menu.choice 'Exit', :exit
          end

          case choice
          when :add_all
            puts '▲ Running git add .'.yellow
            system('git add .')
            diff_cached = `git diff --cached . #{exclusions}`.chomp
          when :exit
            return nil
          end
        end
      elsif diff_cached.empty?
        # Scenario: No changes at all (staged or unstaged)
        # Check if there are ANY unstaged files (maybe untracked?)
        # git status --porcelain includes untracked files
        git_status = `git status --porcelain`.chomp
        if git_status.empty?
          puts '▲ No changes to commit. Working tree clean.'.yellow
          return nil
        else
          # Only untracked files? Or ignored files?
          # If diff_unstaged is empty but git status is not, it usually means untracked files.
          # Let's offer to add them too.
          choice = prompt_no_staged_changes
          case choice
          when :add_all
            puts '▲ Running git add .'.yellow
            system('git add .')
            diff_cached = `git diff --cached . #{exclusions}`.chomp
          when :exit
            return nil
          end
        end
      end

      diff = diff_cached

      # Prepend lock file summary to diff if present
      diff = "#{@lock_file_summary}\n\n#{diff}" if @lock_file_summary

      if diff.length > diff_len
        choice = prompt_diff_handling(diff.length, diff_len)
        case choice
        when :truncate
          puts "▲ Truncating diff to #{diff_len} chars...".yellow
          diff = diff[0...diff_len]
        when :unlimited
          puts "▲ Using full diff (#{diff.length} chars)...".yellow
        when :exit
          return nil
        end
      end

      diff
    end

    def prompt_no_staged_changes
      puts '▲ No staged changes found (but unstaged/untracked files exist).'.yellow
      prompt = TTY::Prompt.new
      begin
        prompt.select('Choose an option:') do |menu|
          menu.choice "Run 'git add .' to stage all changes", :add_all
          menu.choice 'Exit (stage files manually)', :exit
        end
      rescue TTY::Reader::InputInterrupt, Interrupt
        :exit
      end
    end

    def prompt_diff_handling(current_len, max_len)
      puts "▲ The diff is too large (#{current_len} chars, max #{max_len}).".yellow
      prompt = TTY::Prompt.new
      begin
        prompt.select('Choose an option:') do |menu|
          menu.choice "Use first #{max_len} characters to generate commit message", :truncate
          menu.choice 'Use unlimited characters (may fail or be slow)', :unlimited
          menu.choice 'Exit', :exit
        end
      rescue TTY::Reader::InputInterrupt, Interrupt
        :exit
      end
    end

    def detect_lock_file_changes
      # Check both staged and unstaged changes for lock files
      staged_files = `git diff --cached --name-only`.chomp.split("\n")
      unstaged_files = `git diff --name-only`.chomp.split("\n")
      changed_files = (staged_files + unstaged_files).uniq

      updated_locks = LOCK_FILES.select { |lock| changed_files.include?(lock) }
      return nil if updated_locks.empty?

      updated_locks.map { |f| "#{f} updated (dependency changes)" }.join(', ')
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
