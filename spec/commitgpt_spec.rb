# frozen_string_literal: true

require 'spec_helper'
require 'commitgpt/commit_ai'

RSpec.describe CommitGpt do
  let(:commit_ai) { CommitGpt::CommitAi.new }

  it 'has a version number' do
    expect(CommitGpt::VERSION).not_to be nil
  end

  describe '#generate_commit' do
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPResponse) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:read_timeout=)
    end

    context 'with successful API response' do
      it 'gets commit text from OpenAI chat/completions API' do
        allow(response).to receive(:code).and_return('200')

        # Simulate SSE stream with proper data format
        content = 'Add AiCommit module to generate AI-generated commit messages.'
        chunk = "data: #{{ choices: [{ delta: { content: content } }] }.to_json}\n\n"
        done_chunk = "data: [DONE]\n\n"

        allow(http).to receive(:request).and_yield(response)
        allow(response).to receive(:read_body).and_yield(chunk).and_yield(done_chunk)

        # Suppress stdout during test (streaming prints to console)
        expect do
          expect(commit_ai.send(:message, 'test diff')).to eq(content)
        end.to output.to_stdout
      end
    end

    context 'with API error response' do
      it 'returns nil on API error' do
        allow(http).to receive(:request).and_yield(response)
        allow(response).to receive(:code).and_return('500')
        allow(response).to receive(:read_body).and_return({ error: { message: 'Server error' } }.to_json)

        expect do
          expect(commit_ai.send(:message, 'test diff')).to be_nil
        end.to output(/API Error/).to_stdout
      end
    end
  end

  describe '#welcome' do
    context 'with valid configuration' do
      before do
        allow(CommitGpt::ConfigManager).to receive(:config_exists?).and_return(true)
        allow(CommitGpt::ConfigManager).to receive(:get_active_provider_config).and_return({
                                                                                             'api_key' => 'test-key',
                                                                                             'base_url' => 'https://api.openai.com/v1',
                                                                                             'model' => 'gpt-4o-mini'
                                                                                           })
        allow(commit_ai).to receive(:`).with('git rev-parse --is-inside-work-tree').and_return('true')
      end

      it 'shows welcome message and returns true' do
        commit_ai_with_config = CommitGpt::CommitAi.new
        expect { commit_ai_with_config.send(:welcome) }.to output(/Welcome/).to_stdout
      end
    end

    context 'without API key configured' do
      before do
        allow(CommitGpt::ConfigManager).to receive(:config_exists?).and_return(true)
        allow(CommitGpt::ConfigManager).to receive(:get_active_provider_config).and_return({
                                                                                             'api_key' => nil,
                                                                                             'base_url' => 'https://api.openai.com/v1',
                                                                                             'model' => 'gpt-4o-mini'
                                                                                           })
      end

      it 'requires running setup' do
        commit_ai_no_key = CommitGpt::CommitAi.new
        expect { commit_ai_no_key.send(:welcome) }.to output(/aicm setup/).to_stdout
      end
    end
  end
end
