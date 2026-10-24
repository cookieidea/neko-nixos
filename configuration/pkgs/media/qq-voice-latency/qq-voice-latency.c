/*
 * QQ 语音延迟修复：libAVSDKPlugin.so（QAV RTC SDK，进程名 TRAE）打开麦克风时
 * pa_stream_connect_record 的 attr 传 NULL，pipewire-pulse 默认给 2 秒分片
 * （pulse.default.frag = 96000/48000），录音攒满 2 秒才交一次，对方听感 3 秒+。
 *
 * 修法同 libpulse 处理 PULSE_LATENCY_MSEC：对"调用方是 libAVSDKPlugin.so 且
 * 没给 fragsize"的录音流，把 fragsize 设成 30ms 并加 ADJUST_LATENCY。
 * 其余录音流（Chromium 自己给了参数的）一律不插手。
 *
 * QQ_VOICE_LATENCY_MSEC 改毫秒数（默认 30），设 0 关闭。
 * 已设 PULSE_LATENCY_MSEC 时让 libpulse 处理，本库不介入。
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <pulse/pulseaudio.h>

#define LOG(...) fprintf(stderr, "[qq-voice-latency pid=%ld] " __VA_ARGS__), \
                 fflush(stderr)

static char *lookup_env(const char *name)
{
    /* 走 RTLD_NEXT 的 getenv：QQ 可能有自己的 getenv 包装层。 */
    static char *(*next_getenv)(const char *);
    if (!next_getenv)
        next_getenv = (char *(*)(const char *))dlsym(RTLD_NEXT, "getenv");
    return next_getenv ? next_getenv(name) : getenv(name);
}

static int from_avsdk(const void *caller)
{
    Dl_info info;
    if (!dladdr(caller, &info) || !info.dli_fname)
        return 0;
    const char *base = strrchr(info.dli_fname, '/');
    const char *n = base ? base + 1 : info.dli_fname;
    return !strncmp(n, "libAVSDKPlugin.so", 17);
}

static unsigned voice_latency_ms(void)
{
    static int ms = -1;
    if (ms < 0) {
        const char *v = lookup_env("QQ_VOICE_LATENCY_MSEC");
        ms = 30;
        if (v && *v) {
            int n = 0;
            while (*v >= '0' && *v <= '9' && n <= 2000)
                n = n * 10 + (*v++ - '0');
            if (!*v)
                ms = n > 2000 ? 2000 : n;
        }
    }
    return (unsigned)ms;
}

typedef int (*connect_record_fn)(pa_stream *, const char *,
                                 const pa_buffer_attr *, pa_stream_flags_t);

int pa_stream_connect_record(pa_stream *s, const char *dev,
                             const pa_buffer_attr *attr, pa_stream_flags_t flags)
{
    static connect_record_fn real;
    static pa_sample_spec *(*get_spec)(pa_stream *);
    static int (*spec_valid)(const pa_sample_spec *);
    static size_t (*usec_to_bytes)(pa_usec_t, const pa_sample_spec *);
    static int logged;

    if (!real) {
        real = (connect_record_fn)dlsym(RTLD_NEXT, "pa_stream_connect_record");
        get_spec = (pa_sample_spec *(*)(pa_stream *))
            dlsym(RTLD_NEXT, "pa_stream_get_sample_spec");
        spec_valid = (int (*)(const pa_sample_spec *))
            dlsym(RTLD_NEXT, "pa_sample_spec_valid");
        usec_to_bytes = (size_t (*)(pa_usec_t, const pa_sample_spec *))
            dlsym(RTLD_NEXT, "pa_usec_to_bytes");
        if (!real)
            return -PA_ERR_NOTSUPPORTED;
    }

    unsigned ms = voice_latency_ms();
    const pa_sample_spec *spec;
    size_t bytes;

    /* 只管：开着 + 没指定 fragsize + 用户没设 PULSE_LATENCY_MSEC
       + 调用方是 libAVSDKPlugin + 样例规格有效。 */
    if (!ms || (attr && attr->fragsize && attr->fragsize != (uint32_t)-1) ||
        lookup_env("PULSE_LATENCY_MSEC") ||
        !from_avsdk(__builtin_return_address(0)) ||
        !get_spec || !spec_valid || !usec_to_bytes ||
        !(spec = get_spec(s)) || !spec_valid(spec) ||
        !(bytes = usec_to_bytes((pa_usec_t)ms * PA_USEC_PER_MSEC, spec)))
        return real(s, dev, attr, flags);

    pa_buffer_attr a;
    if (attr)
        a = *attr;
    else
        memset(&a, 0xff, sizeof(a));   /* 其余字段全 -1，交给服务端 */
    a.fragsize = (uint32_t)bytes;

    if (!logged) {
        logged = 1;
        LOG("voice capture: libAVSDKPlugin gave no fragsize, using %zu bytes = %u ms",
            bytes, ms);
    }
    return real(s, dev, &a, flags | PA_STREAM_ADJUST_LATENCY);
}
