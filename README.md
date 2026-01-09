<div align="center">
  <div>
    <h1 align="center">Commit GPT</h1>
  </div>
	<p>A CLI that writes your git commit messages for you with AI. Never write a commit message again.</p>
</div>

---

## Installation
```bash
$ gem install commitgpt
```

## Usage

### API Key
Grab your API key and add it as an env variable.
```bash
$ export AICM_KEY=sk-xxxxxxxxxxxxxxxx
```

It's recommended to add this to your `.zshrc` or `.bashrc` so it persists across terminal sessions.

### Custom API Endpoint (Optional)
You can use any OpenAI-compatible API provider by setting `AICM_LINK`:
```bash
# Use a local proxy
$ export AICM_LINK=http://127.0.0.1:8045/v1

# Or use another provider
# Cerebras
$ export AICM_LINK=https://api.cerebras.ai/v1

# Groq
$ export AICM_LINK=https://api.groq.com/openai/v1
```

> **Note**: If you're using a local proxy that doesn't require authentication, you can leave `AICM_KEY` empty.

### List Models
Use `-m` to list all available models from your API provider:
```bash
$ aicm -m
llama3.1-8b
llama-3.3-70b
gpt-4o-mini
```

### aicm
`aicm` is an abbreviation for `AI commits`. After staging your changes with `git add .`, use `aicm` to commit with an AI-generated message.
```bash
$ cd /path/to/your/repo
$ git add .
$ aicm

▲ Welcome to AI Commits!
▲   Generating your AI commit message...

▲ Commit message: git commit -am "Update README.md with contribution instructions and OpenAI API key instructions."

▲ Do you want to commit this message? [y/n]
[main c082637] Update README.md with contribution instructions and OpenAI API key instructions.
 4 files changed, 24 insertions(+), 19 deletions(-)
```

### Update
To update to the latest version:
```bash
$ gem update commitgpt
$ gem cleanup commitgpt
$ gem info commitgpt
```

## Configuration

| Environment Variable | Required | Default | Description |
|---------------------|----------|---------|-------------|
| `AICM_KEY` | No* | `nil` | Your API key. Required when using official OpenAI API. |
| `AICM_LINK` | No | `https://api.openai.com/v1` | Custom API endpoint for OpenAI-compatible services. |
| `AICM_MODEL` | Yes | `gpt-4o-mini` | Model to use for generating commit messages. |
| `AICM_DIFF_LEN` | No | `32768` | Maximum diff length in characters. Increase if you have large diffs. |

\* Required when using the default OpenAI endpoint.

### Available Models

Use `aicm -m` to list models from your provider, or set `AICM_MODEL` directly:

**OpenAI** ([https://api.openai.com/v1](https://platform.openai.com))
```
gpt-5.2 
gpt-5-mini 
gpt-5-nano 
gpt-4o-mini
```

**Cerebras** ([https://api.cerebras.ai/v1](https://cloud.cerebras.ai))
```
zai-glm-4.6
zai-glm-4.7
gpt-oss-120b
llama3.1-8b
llama-3.3-70b
qwen-3-32b
qwen-3-235b-a22b-instruct-2507

```

**Groq** ([https://api.groq.com/openai/v1](https://console.groq.com))
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

## Limitations
- Only supports git diffs up to `AICM_DIFF_LEN` characters (default 32K)
- The generated commit message can't be edited interactively, but you can choose `n` and copy the command to edit manually

## Special Thanks
I used ChatGPT to convert `AICommits` from TypeScript to Ruby. Special thanks to [https://github.com/Nutlope/aicommits](https://github.com/Nutlope/aicommits)

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/ZPVIP/commitgpt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/main/CODE_OF_CONDUCT.md).

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the CommitGpt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/master/CODE_OF_CONDUCT.md).
