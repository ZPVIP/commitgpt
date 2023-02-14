# Commit GPT

Welcome to your Commit GPT! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/commitgpt`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation
```bash
$ gem install commitgpt
```

## Usage
```bash
$ export OPENAI_KEY=sk-xxxxxxxxxxxxxxxx
$ cd /path/to/your/repo
$ git add .
$ aicm
```
It's recommended to add the first line to your `.zshrc` or `.bashrc` so it persists instead of having to define it in each terminal session.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Special Thanks
I used chatGPT to convert `AICommits` to `CommitGPT`. Thanks to [https://github.com/Nutlope/aicommits](https://github.com/Nutlope/aicommits)   

## How it works
This CLI tool runs a git diff command to grab all the latest changes, sends this to OpenAI's GPT-3, then returns the AI generated commit message. I also want to note that it does cost money since GPT-3 generations aren't free. However, OpenAI gives folks $18 of free credits and commit message generations are cheap so it should be free for a long time.

## Limitations
Only supports git diffs of up to 200 lines of code for now
The generated commit message can't be edited yet, but you can choose `n` and copy the commit command and edit it manually.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ZPVIP/commitgpt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/commitgpt/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CommitGpt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ZPVIP/commitgpt/blob/master/CODE_OF_CONDUCT.md).
