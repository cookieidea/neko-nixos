import json, sys

output_path = sys.argv[1]  # ~/.config/mark-shot/config.json (writable)
source_path = sys.argv[2]  # /nix/store/... (read-only base config)

secret = json.load(open("/run/agenix/mark-shot-sensitive"))
config = json.load(open(source_path))

# 注入敏感值
config["translation"]["youdao"]["appKey"] = secret.get("youdaoAppKey", "")
config["translation"]["youdao"]["appSecret"] = secret.get("youdaoAppSecret", "")
config["upload"]["env"]["MARK_SHOT_UPLOAD_FIELD_key"] = secret.get("freeimageKey", "")

json.dump(config, open(output_path, "w"), indent=4, ensure_ascii=False)
