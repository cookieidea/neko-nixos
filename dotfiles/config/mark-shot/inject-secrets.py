import json, sys
secret = json.load(open("/run/agenix/mark-shot-sensitive"))
config = json.load(open("/home/cookie/.config/mark-shot/config.json"))
config.setdefault("translation", {}).setdefault("youdao", {})["appKey"] = secret.get("youdaoAppKey", "")
config.setdefault("translation", {}).setdefault("youdao", {})["appSecret"] = secret.get("youdaoAppSecret", "")
config.setdefault("upload", {}).setdefault("env", {})["MARK_SHOT_UPLOAD_FIELD_key"] = secret.get("freeimageKey", "")
# 非敏感 upload 配置
config["upload"] = {
    "command": "",
    "env": {
        "MARK_SHOT_UPLOAD_URL": "https://freeimage.host/api/1/upload",
        "MARK_SHOT_UPLOAD_FIELD": "source",
        "MARK_SHOT_UPLOAD_URL_PATH": "image.url",
        "MARK_SHOT_UPLOAD_DELETE_URL_PATH": "",
        "MARK_SHOT_UPLOAD_FIELD_key": secret.get("freeimageKey", "")
    },
    "timeoutMs": 60000
}
json.dump(config, open("/home/cookie/.config/mark-shot/config.json", "w"), indent=4, ensure_ascii=False)
