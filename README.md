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
### API key
grab your [OpenAI key](https://openai.com/api/) and add it as an env variable.
```bash
$ export OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx
```
It's recommended to add the first line to your `.zshrc` or `.bashrc` so it persists instead of having to define it in each terminal session.
    
### aicm
`aicm` is an abbreviation for `AI commits`, after `git add .` add your file to stage, then use `aicm` to commit with an AI generated commit message.
```bash
$ cd /path/to/your/repo
$ git add .
$ aicm
```

## Special Thanks
I used chatGPT to convert `AICommits`(JS) to `CommitGPT`(Ruby). Thanks to [https://github.com/Nutlope/aicommits](https://github.com/Nutlope/aicommits)   

## How it works
This CLI tool runs a git diff command to grab all the latest changes, sends this to OpenAI's GPT-3, then returns the AI generated commit message. I also want to note that it does cost money since GPT-3 generations aren't free. However, OpenAI gives folks $18 of free credits and commit message generations are cheap so it should be free for a long time.

## Limitations
Only supports git diffs of up to 200 lines of code for now
The generated commit message can't be edited yet, but you can choose `n` and copy the commit command and edit it manually.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ZPVIP/commitgpt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CommitGpt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/master/CODE_OF_CONDUCT.md).
