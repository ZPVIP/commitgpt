# frozen_string_literal: true

class Commitgpt < Formula
  desc 'A CLI AI that writes git commit messages for you'
  homepage 'https://github.com/ZPVIP/commitgpt'
  url 'https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.7.tar.gz'
  sha256 '00749992b64c125833da62a664969bf0619c4b985b661b7a40538703880b35b2'
  license 'MIT'

  depends_on 'ruby'

  def install
    ENV['GEM_HOME'] = libexec
    system 'gem', 'build', "#{name}.gemspec"
    system 'gem', 'install', "#{name}-#{version}.gem"
    bin.install libexec / 'bin/aicm'
    bin.env_script_all_files(libexec / 'bin', GEM_HOME: ENV.fetch('GEM_HOME', nil))
  end

  test do
    system "#{bin}/aicm", '--version'
  end
end
