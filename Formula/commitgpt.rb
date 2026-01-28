class Commitgpt < Formula
  desc "A CLI AI that writes git commit messages for you"
  homepage "https://github.com/ZPVIP/commitgpt"
  url "https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "<PLACEHOLDER_SHA256>"
  license "MIT"

  depends_on "ruby"

  def install
    ENV["GEM_HOME"] = libexec
    system "gem", "build", "#{name}.gemspec"
    system "gem", "install", "#{name}-#{version}.gem"
    bin.install libexec/"bin/#{name}"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    system "#{bin}/aicm", "--version"
  end
end
