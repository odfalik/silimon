# Homebrew formula for Silimon
# To use: brew tap <your-username>/silimon && brew install silimon

class Silimon < Formula
  desc "Apple Silicon performance monitor for your menu bar"
  homepage "https://github.com/odfalik/silimon"
  url "https://github.com/odfalik/silimon/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "fe3597e024a1cdf8675deae647e4008756bd4eaf09dfc59e536acd290a9b5bd9"
  license "MIT"
  head "https://github.com/odfalik/silimon.git", branch: "main"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/silimon"

    # Install scripts
    (pkgshare/"scripts").install "Scripts/setup-sudo.sh"
    (pkgshare/"scripts").install "Scripts/uninstall.sh"
  end

  def post_install
    # Create sudoers entry for passwordless powermetrics
    sudoers_file = "/etc/sudoers.d/silimon"
    unless File.exist?(sudoers_file)
      ohai "Setting up passwordless powermetrics access..."
      ohai "You may be prompted for your password."
      system "sudo", "sh", "-c", "echo '%admin ALL=(root) NOPASSWD: /usr/bin/powermetrics' > #{sudoers_file}"
      system "sudo", "chmod", "0440", sudoers_file
    end
  end

  def caveats
    <<~EOS
      Silimon monitors Apple Silicon performance metrics in your menu bar.

      Features:
        - Real-time power consumption (CPU, GPU, ANE)
        - CPU cluster frequencies (E-cores vs P-cores)
        - Memory usage and pressure
        - GPU utilization

      To start silimon:
        silimon

      To enable Touch ID for sudo (optional):
        sudo sed -i '' '2i\\
      auth       sufficient     pam_tid.so
      ' /etc/pam.d/sudo

      To uninstall completely:
        brew uninstall silimon
        sudo rm /etc/sudoers.d/silimon
    EOS
  end

  test do
    assert_match "silimon", shell_output("#{bin}/silimon --help 2>&1", 1)
  end
end
