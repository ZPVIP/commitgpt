# frozen_string_literal: true

module CommitGpt
  # Provider presets for common AI providers
  PROVIDER_PRESETS = [
    { label: 'Anthropic Claude', value: 'anthropic', base_url: 'https://api.anthropic.com/v1' },
    { label: 'Cerebras', value: 'cerebras', base_url: 'https://api.cerebras.ai/v1' },
    { label: 'DeepSeek', value: 'deepseek', base_url: 'https://api.deepseek.com' },
    { label: 'Google AI', value: 'gemini', base_url: 'https://generativelanguage.googleapis.com/v1beta/openai' },
    { label: 'Groq', value: 'groq', base_url: 'https://api.groq.com/openai/v1' },
    { label: 'LLaMa.cpp', value: 'llamacpp', base_url: 'http://127.0.0.1:8080/v1' },
    { label: 'LM Studio', value: 'lmstudio', base_url: 'http://127.0.0.1:1234/v1' },
    { label: 'Llamafile', value: 'llamafile', base_url: 'http://127.0.0.1:8080/v1' },
    { label: 'Mistral', value: 'mistral', base_url: 'https://api.mistral.ai/v1' },
    { label: 'NVIDIA NIM', value: 'nvidia_nim', base_url: 'https://integrate.api.nvidia.com/v1' },
    { label: 'Ollama', value: 'ollama', base_url: 'http://127.0.0.1:11434/v1' },
    { label: 'OpenAI', value: 'openai', base_url: 'https://api.openai.com/v1' },
    { label: 'OpenRouter', value: 'openrouter', base_url: 'https://openrouter.ai/api/v1' }
  ].freeze
end
