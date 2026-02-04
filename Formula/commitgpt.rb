# frozen_string_literal: true

class Commitgpt < Formula
  desc 'A CLI AI that writes git commit messages for you'
  homepage 'https://github.com/ZPVIP/commitgpt'
  url 'https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.4.tar.gz'
  sha256 '3821af620c568c8e533f26397ea3163e1af902f5846444e774127ebe09c5af7d'
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
