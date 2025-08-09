class AppearanceNotify < Formula
  desc "macOS daemon that executes hooks on system appearance changes"
  homepage "https://github.com/odysseus0/appearance-notify"
  version "0.2.0"
  license "MIT"
  
  depends_on macos: :sonoma
  
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/odysseus0/appearance-notify/releases/download/v0.2.0/appearance-notify-aarch64-apple-darwin.tar.gz"
      sha256 "96503b5b86d2b84f1c92081e8112f9c60ec9d02c59b7a18d1b3094485f610afc"
    else
      url "https://github.com/odysseus0/appearance-notify/releases/download/v0.2.0/appearance-notify-x86_64-apple-darwin.tar.gz"
      sha256 "a5bdc2f6f7d81be75d9869a6e72f703c1eabe17d437488248b7d7917bebd9d9e"
    end
  end
  
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
