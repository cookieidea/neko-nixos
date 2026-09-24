import json
import os
import sys
import tempfile

config_path = sys.argv[1]
secret_path = "/run/agenix/mark-shot-sensitive"

with open(secret_path, encoding="utf-8") as file:
    secret = json.load(file)

with open(config_path, encoding="utf-8") as file:
    config = json.load(file)

translation = config.get("translation")
if not isinstance(translation, dict):
    translation = {}
    config["translation"] = translation

youdao = translation.get("youdao")
if not isinstance(youdao, dict):
    youdao = {}
    translation["youdao"] = youdao

upload = config.get("upload")
if not isinstance(upload, dict):
    upload = {}
    config["upload"] = upload

upload_env = upload.get("env")
if not isinstance(upload_env, dict):
    upload_env = {}
    upload["env"] = upload_env

youdao["appKey"] = secret.get("youdaoAppKey", "")
youdao["appSecret"] = secret.get("youdaoAppSecret", "")
upload_env["MARK_SHOT_UPLOAD_FIELD_key"] = secret.get("freeimageKey", "")

fd, temp_path = tempfile.mkstemp(
    dir=os.path.dirname(config_path),
    prefix=".mark-shot-config.",
    text=True,
)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as file:
        json.dump(config, file, indent=4, ensure_ascii=False)
        file.write("\n")
    os.chmod(temp_path, 0o600)
    os.replace(temp_path, config_path)
except Exception:
    try:
        os.unlink(temp_path)
    except FileNotFoundError:
        pass
    raise
