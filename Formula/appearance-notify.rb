class AppearanceNotify < Formula
  desc "macOS daemon that executes hooks on system appearance changes"
  homepage "https://github.com/odysseus0/appearance-notify"
  version "0.2.0"
  license "MIT"

  url "https://github.com/odysseus0/appearance-notify/releases/download/v0.2.0/appearance-notify-apple-darwin.tar.gz"
  sha256 "fe805fa107bfbe6739190b94287199162d035acf7f00f25597b398b8c1265058" # universal

  depends_on macos: :sonoma

  def install
    bin.install "appearance-notify"

    (prefix/"io.github.odysseus0.appearance-notify.plist").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>io.github.odysseus0.appearance-notify</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{opt_bin}/appearance-notify</string>
              <string>daemon</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
      </dict>
      </plist>
    EOS
  end

  service do
    run [opt_bin/"appearance-notify", "daemon"]
    keep_alive true
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/appearance-notify --version")
  end
end
