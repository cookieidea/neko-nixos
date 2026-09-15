# mpv:// 协议处理器（Linux 版 mpv-handler-openlist）
# OpenList 网页“用mpv打开”生成 mpv://<URL编码的真实地址>，
# 这里解码后直接 exec mpv（对标上游 Go 版 handleURL 逻辑）
{ pkgs }:
pkgs.writers.writePython3Bin "mpv-handler" { } ''
  import os
  import sys
  from urllib.parse import unquote

  MPV = "${pkgs.mpv}/bin/mpv"
  LOG = os.path.join(os.path.expanduser("~"), ".cache", "mpv-handler.log")

  def log(msg):
      try:
          with open(LOG, "a", encoding="utf-8") as f:
              f.write(msg + "\n")
      except Exception:
          pass

  def main():
      raw = sys.argv[1] if len(sys.argv) > 1 else ""
      log("raw: " + raw)
      prefix = "mpv://"
      if not raw.startswith(prefix):
          log("ERR: invalid scheme")
          return 1
      url = unquote(raw[len(prefix):]).strip()
      if not url:
          log("ERR: empty url after decode")
          return 1
      log("exec: " + MPV + " " + url)
      os.execv(MPV, ["mpv", url])
      return 0

  if __name__ == "__main__":
      sys.exit(main())
''
