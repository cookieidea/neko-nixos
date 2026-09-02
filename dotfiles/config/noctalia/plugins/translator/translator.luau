--!nonstrict
-- Translator launcher provider.
--
-- Usage from the launcher: `/tr <lang> <text>` - e.g. `/tr es hello world`.
-- If the first word is not a language, the whole query is translated to the
-- configured default target. Press Enter on a result to copy it to the clipboard.
-- Translation uses Google Translate's public `translate_a/single` endpoint.

local DEFAULT_TARGET = noctalia.getConfig("target_lang")
DEFAULT_TARGET = if type(DEFAULT_TARGET) == "string" and DEFAULT_TARGET ~= "" then DEFAULT_TARGET else "en"

-- Common language aliases → ISO code. Any other 2–3 letter token is passed
-- through to Google as-is, so uncommon languages still work.
local LANGUAGES = {
  ar = { "arabic", "arabe" },
  cs = { "czech", "tcheque" },
  de = { "german", "allemand", "deutsch" },
  el = { "greek", "grec" },
  en = { "english", "anglais" },
  es = { "spanish", "espagnol", "espanol" },
  fa = { "persian", "farsi", "persan" },
  fi = { "finnish", "finnois" },
  fr = { "french", "francais" },
  he = { "hebrew", "hebreu" },
  hi = { "hindi" },
  hu = { "hungarian", "hongrois" },
  id = { "indonesian", "indonesien" },
  it = { "italian", "italien" },
  ja = { "japanese", "japonais" },
  ko = { "korean", "coreen" },
  nl = { "dutch", "neerlandais" },
  no = { "norwegian", "norvegien" },
  pl = { "polish", "polonais" },
  pt = { "portuguese", "portugais" },
  ro = { "romanian", "roumain" },
  ru = { "russian", "russe" },
  sv = { "swedish", "suedois" },
  tr = { "turkish", "turc" },
  uk = { "ukrainian", "ukrainien" },
  vi = { "vietnamese", "vietnamien" },
  zh = { "chinese", "chinois", "mandarin" },
}

-- target|text -> translation; pending guards against duplicate in-flight fetches.
local cache = {}
local pending = {}

-- Resolve a token to a language code: a known alias, or a bare 2–3 letter code.
local function resolveLang(token)
  local lower = token:lower()
  for code, aliases in LANGUAGES do
    if code == lower or table.find(aliases, lower) then
      return code
    end
  end
  if lower:match("^%a%a%a?$") then
    return lower
  end
  return nil
end

-- Google returns [[[ "segment", "orig", ... ], ...], ...]; the translation is the
-- concatenation of segment[1] across the first array.
local function parseGoogle(body)
  local decoded = noctalia.json.decode(body)
  if type(decoded) ~= "table" or type(decoded[1]) ~= "table" then
    return nil
  end
  local parts = {}
  for _, segment in decoded[1] do
    if type(segment) ~= "table" or type(segment[1]) ~= "string" then
      continue
    end
    table.insert(parts, segment[1])
  end
  if #parts == 0 then
    return nil
  end
  return table.concat(parts)
end

-- MyMemory 免费翻译 API（国内直连，无需 key/token）
-- 免费版限制：每 IP 每天约 5000 词；无自动语言检测

local LANG_MAP = {
  zh = "zh-CN", ar = "ar", cs = "cs", de = "de", el = "el", en = "en",
  es = "es", fa = "fa", fi = "fi", fr = "fr", he = "he", hi = "hi",
  hu = "hu", id = "id", it = "it", ja = "ja", ko = "ko", nl = "nl",
  no = "no", pl = "pl", pt = "pt", ro = "ro", ru = "ru", sv = "sv",
  tr = "tr", uk = "uk", vi = "vi",
}

-- MyMemory 无自动检测 → 启发式判断源语言（含 CJK 字符视为中文，否则英文）
local function guessSource(text)
  if text:match("[\xE4-\xE9][\x80-\xBF][\x80-\xBF]") then
    return "zh-CN"
  end
  return "en"
end

local function fetchGoogle(text, target, onDone)
  local tl = LANG_MAP[target] or target
  local sl = guessSource(text)
  local url = `https://api.mymemory.translated.net/get?q={noctalia.string.urlEncode(text)}&langpair={sl}|{noctalia.string.urlEncode(tl)}`
  noctalia.http({ url = url }, function(res)
    if not res.ok then
      onDone(nil, "Connection error - is the network up?")
      return
    end
    local ok, decoded = pcall(noctalia.json.decode, res.body)
    if ok and decoded and decoded.responseData and decoded.responseData.translatedText then
      onDone(decoded.responseData.translatedText, nil)
    else
      onDone(nil, "Translation error")
    end
  end)
end

local function hintRow(title, subtitle, glyph)
  return { id = title, title = title, subtitle = subtitle, glyph = glyph }
end

local function resultRow(translated, target)
  return {
    id = translated,
    title = translated,
    subtitle = `Translation ({target}) - press Enter to copy`,
    glyph = "language",
    presentation = "detail",
  }
end

function onQuery(query)
  local text = noctalia.string.trim(query)
  if text == "" then
    launcher.setResults(query, { hintRow("Translate text", "Type: <lang> <text> - e.g. es hello", "language") })
    return
  end

  local first, rest = text:match("^(%S+)%s+([%s%S]*)$")
  local target, content
  if first then
    local code = resolveLang(first)
    if code then
      target = code
      content = rest
    else
      target = DEFAULT_TARGET
      content = text
    end
  else
    if resolveLang(text) then
      launcher.setResults(query, { hintRow("Type text to translate", `Target language: {text}`, "language") })
      return
    end
    target = DEFAULT_TARGET
    content = text
  end

  if noctalia.string.trim(content) == "" then
    launcher.setResults(query, { hintRow("Type text to translate", `Target language: {target}`, "language") })
    return
  end

  local key = `{target}|{content}`
  local cached = cache[key]
  if cached then
    launcher.setResults(query, { resultRow(cached, target) })
    return
  end

  launcher.setResults(query, { hintRow("Translating…", content, "loader") })
  if not pending[key] then
    pending[key] = true
    fetchGoogle(content, target, function(translated, err)
      pending[key] = nil
      if translated then
        cache[key] = translated
        launcher.setResults(query, { resultRow(translated, target) })
      else
        launcher.setResults(query, { hintRow(err or "Translation error", content, "alert-triangle") })
      end
    end)
  end
end

function onActivate(id)
  if id ~= "" then
    noctalia.copyToClipboard(id, "text/plain")
    noctalia.notify("Translator", "Copied to clipboard")
  end
end
