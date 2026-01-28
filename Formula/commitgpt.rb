class Commitgpt < Formula
  desc "A CLI AI that writes git commit messages for you"
  homepage "https://github.com/ZPVIP/commitgpt"
  url "https://github.com/ZPVIP/commitgpt/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "ce049f516a7650bd12a8b2a3018a6b3dacccfbf25ac8725abbfff0bb61d0c8d9"
  license "MIT"

  depends_on "ruby"

  def install
    ENV["GEM_HOME"] = libexec
    system "gem", "build", "#{name}.gemspec"
    system "gem", "install", "#{name}-#{version}.gem"
    bin.install libexec/"bin/aicm"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    system "#{bin}/aicm", "--version"
  end
end
