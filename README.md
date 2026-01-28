<div align="center">
  <div>
    <h1 align="center">Commit GPT</h1>
  </div>
	<p>A CLI that writes your git commit messages for you with AI. Never write a commit message again.</p>
</div>

---

## Installation

### Prerequisites: Install Ruby

If you don't have Ruby installed, follow these steps first.

<details>
<summary><strong>macOS</strong></summary>

**1. Install Homebrew** (skip if already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**2. Install Ruby dependencies**

```bash
brew install openssl@3 libyaml gmp rust
```

</details>

<details>
<summary><strong>Ubuntu / Debian</strong></summary>

**Install Ruby dependencies**

```bash
sudo apt-get update
sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev
```

</details>

**Install Ruby with Mise** (version manager)

```bash
# Install Mise
curl https://mise.run | sh

# For zsh (macOS default)
echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.zshrc
source ~/.zshrc

# For bash (Ubuntu default)
# echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.bashrc
# source ~/.bashrc

# Install Ruby
mise use --global ruby@3

# Verify installation
ruby --version
#=> 3.4.7

# Update RubyGems
gem update --system
```

### Install CommitGPT


### Prerequisites: Install Ruby

If you don't have Ruby installed, follow these steps first.

<details>
<summary><strong>macOS</strong></summary>

**1. Install Homebrew** (skip if already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**2. Install Ruby dependencies**

```bash
brew install openssl@3 libyaml gmp rust
```

</details>

<details>
<summary><strong>Ubuntu / Debian</strong></summary>

**Install Ruby dependencies**

```bash
sudo apt-get update
sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev
```

</details>

**Install Ruby with Mise** (version manager)

```bash
# Install Mise
curl https://mise.run | sh

# For zsh (macOS default)
echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.zshrc
source ~/.zshrc

# For bash (Ubuntu default)
# echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.bashrc
# source ~/.bashrc

# Install Ruby
mise use --global ruby@3

# Verify installation
ruby --version
#=> 3.4.7

# Update RubyGems
gem update --system
```

### Install CommitGPT

```bash
gem install commitgpt
gem install commitgpt
```

## Configuration

CommitGPT uses a YAML configuration system (`~/.config/commitgpt/`) to support multiple providers and per-provider settings.

### Interactive Setup (Recommended)
Run the setup wizard to configure your provider:
```bash
$ aicm setup
```

You'll be guided to:
1. Choose an AI provider (Presets: Cerebras, OpenAI, Ollama, Groq, etc.)
2. Enter your API Key (stored securely in `config.local.yml`)
3. Select a model interactively
4. Set maximum diff length

**Note:** Please add `~/.config/commitgpt/config.local.yml` to your `.gitignore` if you are syncing your home directory, as it contains your API keys.

---

## Usage

### Generate Commit Message
Stage your changes and run `aicm`:
```bash
$ git add .
$ aicm
```

### Switch Provider
Switch between configured providers easily:
```bash
$ aicm -p
# or
$ aicm --provider
```

### Select Model
Interactively list and select a model for your current provider:
```bash
$ aicm -m
# or
$ aicm --models
```

### Check Configuration
View your current configuration (Provider, Model, Base URL, Diff Len):
```bash
$ aicm help
```

### View Git Diff
Preview the diff that will be sent to the AI:
```bash
$ aicm -v
```

### Update
To update to the latest version:
```bash
$ gem update commitgpt
```

---

### Supported Providers
We support any OpenAI-compatible API. Presets available for:
- **Cerebras** (Fast & Recommended)
- **OpenAI** (Official)
- **Ollama** (Local)
- **Groq**
- **DeepSeek**
- **Anthropic (Claude)**
- **Google AI (Gemini)**
- **Mistral**
- **OpenRouter**
- **Local setups** (LM Studio, LLaMa.cpp, Llamafile)

### Recommended Providers

**OpenAI** ([https://platform.openai.com](https://platform.openai.com))
```
gpt-5.2 
gpt-5-mini 
gpt-5-nano 
gpt-4o-mini
```

**Cerebras** ([https://cloud.cerebras.ai](https://cloud.cerebras.ai)) ⭐ Recommended
```
zai-glm-4.7          # ⭐ Best for commit messages - fast & accurate
zai-glm-4.6
gpt-oss-120b
llama3.1-8b
llama-3.3-70b
qwen-3-32b
qwen-3-235b-a22b-instruct-2507
```

**Groq** ([https://console.groq.com](https://console.groq.com))
```
llama-3.3-70b-versatile
llama-3.1-8b-instant
meta-llama/llama-4-maverick-17b-128e-instruct
meta-llama/llama-4-scout-17b-16e-instruct
qwen/qwen3-32b
moonshotai/kimi-k2-instruct-0905
openai/gpt-oss-120b
groq/compound
groq/compound-mini
```


## How It Works
This CLI tool runs a `git diff` command to grab all staged changes, sends this to OpenAI's GPT API (or compatible endpoint), and returns an AI-generated commit message. The tool uses the `/v1/chat/completions` endpoint with optimized prompts for generating conventional commit messages.

## Special Thanks
I used ChatGPT to convert `AICommits` from TypeScript to Ruby. Special thanks to [https://github.com/Nutlope/aicommits](https://github.com/Nutlope/aicommits)

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/ZPVIP/commitgpt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/main/CODE_OF_CONDUCT.md).

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the CommitGpt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/master/CODE_OF_CONDUCT.md).
