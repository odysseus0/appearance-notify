class AppearanceNotify < Formula
  desc "macOS daemon that executes hooks on system appearance changes"
  homepage "https://github.com/odysseus0/appearance-notify"
  version "0.1.0"
  license "MIT"
  
  depends_on macos: :sonoma
  
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/odysseus0/appearance-notify/releases/download/v0.1.0/appearance-notify-aarch64-apple-darwin.tar.gz"
      sha256 "987c1dbbf8a42434d34d4aa08a1d190d7e0c93d70a9d70e735ea662f95ffbd45"
    else
      url "https://github.com/odysseus0/appearance-notify/releases/download/v0.1.0/appearance-notify-x86_64-apple-darwin.tar.gz"
      sha256 "32749a303f2d9addefecbbb404c4f59536752d19095eca4ad1a8670d2bc3f1aa"
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
    run opt_bin/"appearance-notify"
    keep_alive true
  end
  
  test do
    assert_match "appearance-notify", shell_output("#{bin}/appearance-notify --version 2>&1", 1)
  end
end