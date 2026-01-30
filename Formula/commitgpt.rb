# frozen_string_literal: true

class Commitgpt < Formula
  desc 'A CLI AI that writes git commit messages for you'
  homepage 'https://github.com/ZPVIP/commitgpt'
  url 'https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.3.tar.gz'
  sha256 '7f9865ceb67f083d0b09cd9dc07644ec3d99b2f889a10b230b17b09c0c6cfc1e'
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
