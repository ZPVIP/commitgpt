# frozen_string_literal: true

class Commitgpt < Formula
  desc 'A CLI AI that writes git commit messages for you'
  homepage 'https://github.com/ZPVIP/commitgpt'
  url 'https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.6.tar.gz'
  sha256 '02354cdb1a9abaa4c72e223553cde97af3de6b041b7fc9e08cb1a5d198a023ab'
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
