# Homebrew formula for Silimon
# To use: brew tap <your-username>/silimon && brew install silimon

class Silimon < Formula
  desc "Apple Silicon performance monitor for your menu bar"
  homepage "https://github.com/odfalik/silimon"
  url "https://github.com/odfalik/silimon/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/odfalik/silimon.git", branch: "main"

  depends_on arch: :arm64
  depends_on macos: :ventura
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/silimon"
  end

  def caveats
    <<~EOS
      Silimon monitors Apple Silicon performance metrics in your menu bar.

      Features:
        - Real-time power consumption (CPU, GPU, ANE)
        - CPU cluster frequencies (E-cores vs P-cores)
        - Memory usage and pressure
        - GPU utilization
        - Network throughput
        - Battery status

      No sudo required! Start silimon with:
        silimon

      If metrics aren't working, open Settings and click "Diagnose"
      to run system diagnostics.

      To uninstall:
        brew uninstall silimon
    EOS
  end

  test do
    assert_match "silimon", shell_output("#{bin}/silimon --version")
  end
end
