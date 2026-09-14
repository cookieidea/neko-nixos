import json, sys
secret = json.load(open("/run/agenix/mark-shot-sensitive"))
config = json.load(open("/home/cookie/.config/mark-shot/config.json"))
config.setdefault("translation", {}).setdefault("youdao", {})["appKey"] = secret.get("youdaoAppKey", "")
config.setdefault("translation", {}).setdefault("youdao", {})["appSecret"] = secret.get("youdaoAppSecret", "")
config.setdefault("upload", {}).setdefault("env", {})["MARK_SHOT_UPLOAD_FIELD_key"] = secret.get("freeimageKey", "")
json.dump(config, open("/home/cookie/.config/mark-shot/config.json", "w"), indent=4, ensure_ascii=False)
