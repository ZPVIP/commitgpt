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

  describe "AICM_LINK configuration" do
    it "uses default OpenAI API link" do
      expect(CommitGpt::CommitAi::AICM_LINK).to eq("https://api.openai.com/v1")
    end
  end

  describe "#welcome" do
    context "without API key but with custom link" do
      before do
        stub_const("CommitGpt::CommitAi::AICM_KEY", nil)
        stub_const("CommitGpt::CommitAi::AICM_LINK", "http://127.0.0.1:8045/v1")
        allow(commit_ai).to receive(:`).with("git rev-parse --is-inside-work-tree").and_return("true")
      end

      it "allows proceeding without API key for custom endpoints" do
        expect { commit_ai.send(:welcome) }.to output(/Welcome/).to_stdout
      end
    end

    context "without API key and default link" do
      before do
        stub_const("CommitGpt::CommitAi::AICM_KEY", nil)
        stub_const("CommitGpt::CommitAi::AICM_LINK", "https://api.openai.com/v1")
      end

      it "requires API key for default OpenAI endpoint" do
        expect { commit_ai.send(:welcome) }.to output(/AICM_KEY/).to_stdout
      end
    end
  end
end
