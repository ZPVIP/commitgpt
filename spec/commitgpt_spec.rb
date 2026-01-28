# frozen_string_literal: true

require "spec_helper"
require "commitgpt/commit_ai"

RSpec.describe CommitGpt do
  let(:commit_ai) { CommitGpt::CommitAi.new }

  it "has a version number" do
    expect(CommitGpt::VERSION).not_to be nil
  end

  describe "#generate_commit" do
    context "with successful API response" do
      it "gets commit text from OpenAI chat/completions API" do
        allow(HTTParty).to receive(:post).and_return(
          {
            "id" => "chatcmpl-abc123",
            "object" => "chat.completion",
            "created" => 1_676_409_742,
            "model" => "gpt-4o-mini",
            "choices" => [
              {
                "index" => 0,
                "message" => {
                  "role" => "assistant",
                  "content" => "Add AiCommit module to generate AI-generated commit messages."
                },
                "finish_reason" => "stop"
              }
            ],
            "usage" => { "prompt_tokens" => 100, "completion_tokens" => 13, "total_tokens" => 113 }
          }
        )
        expect(commit_ai.send(:message, "test diff")).to eq("Add AiCommit module to generate AI-generated commit messages.")
      end
    end
  describe "#generate_commit" do
    context "with successful API response" do
      it "gets commit text from OpenAI chat/completions API" do
        allow(HTTParty).to receive(:post).and_return(
          {
            "id" => "chatcmpl-abc123",
            "object" => "chat.completion",
            "created" => 1_676_409_742,
            "model" => "gpt-4o-mini",
            "choices" => [
              {
                "index" => 0,
                "message" => {
                  "role" => "assistant",
                  "content" => "Add AiCommit module to generate AI-generated commit messages."
                },
                "finish_reason" => "stop"
              }
            ],
            "usage" => { "prompt_tokens" => 100, "completion_tokens" => 13, "total_tokens" => 113 }
          }
        )
        expect(commit_ai.send(:message, "test diff")).to eq("Add AiCommit module to generate AI-generated commit messages.")
      end
    end

    context "with API error response" do
      it "returns nil on API error" do
        allow(HTTParty).to receive(:post).and_return(
    context "with API error response" do
      it "returns nil on API error" do
        allow(HTTParty).to receive(:post).and_return(
          {
            "error" => {
              "message" => "The server had an error while processing your request.",
              "type" => "server_error",
              "param" => nil,
              "code" => nil
            }
          }
        )
        expect(commit_ai.send(:message, "test diff")).to eq(nil)
      end
    end
  end

  describe "#welcome" do
    context "with valid configuration" do
      before do
        allow(CommitGpt::ConfigManager).to receive(:config_exists?).and_return(true)
        allow(CommitGpt::ConfigManager).to receive(:get_active_provider_config).and_return({
          "api_key" => "test-key",
          "base_url" => "https://api.openai.com/v1",
          "model" => "gpt-4o-mini"
        })
        allow(commit_ai).to receive(:`).with("git rev-parse --is-inside-work-tree").and_return("true")
      end

      it "shows welcome message and returns true" do
        commit_ai_with_config = CommitGpt::CommitAi.new
        expect { commit_ai_with_config.send(:welcome) }.to output(/Welcome/).to_stdout
      end
    end

    context "without API key configured" do
      before do
        allow(CommitGpt::ConfigManager).to receive(:config_exists?).and_return(true)
        allow(CommitGpt::ConfigManager).to receive(:get_active_provider_config).and_return({
          "api_key" => nil,
          "base_url" => "https://api.openai.com/v1",
          "model" => "gpt-4o-mini"
        })
      end

      it "requires running setup" do
        commit_ai_no_key = CommitGpt::CommitAi.new
        expect { commit_ai_no_key.send(:welcome) }.to output(/aicm setup/).to_stdout
      end
    end
  end
end
