# frozen_string_literal: true

require "spec_helper"
require "commitgpt/commit_ai"

RSpec.describe CommitGpt do
  let(:commit_ai) { CommitGpt::CommitAi.new }

  it "has a version number" do
    expect(CommitGpt::VERSION).not_to be nil
  end

  describe "aicm" do
    it "gets commit text from OpenAI API" do
      allow(HTTParty).to receive(:post).and_return(
        { "id" => "cmpl-7joXJpCMcd0620evfesv8BGCXXX99",
          "object" => "text_completion",
          "created" => 1_676_409_742,
          "model" => "text-davinci-003",
          "choices" => [
            { "text" => "Add AiCommit module to generate AI-generated commit messages.",
              "index" => 0,
              "logprobs" => nil,
              "finish_reason" => "stop" }
          ],
          "usage" => { "prompt_tokens" => 2856, "completion_tokens" => 13, "total_tokens" => 2869 } }
      )
      expect(commit_ai.send(:message)).to eq("Add AiCommit module to generate AI-generated commit messages.")
    end
  end

  it "gets no commit text from OpenAI API" do
    allow(HTTParty).to receive(:post).and_return(
      {
        "error" =>
          {
            "message" => "The server had an error while processing your request. Sorry about that!",
            "type" => "server_error",
            "param" => nil,
            "code" => nil
          }
      }
    )
    expect(commit_ai.send(:message)).to eq(nil)
  end
end
