# frozen_string_literal: true

class Commitgpt < Formula
  desc 'A CLI AI that writes git commit messages for you'
  homepage 'https://github.com/ZPVIP/commitgpt'
  url 'https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.5.tar.gz'
  sha256 '56476926da4f199e182e160ed38062721cb33fd72344c5a9f1c0b61950f642dd'
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
