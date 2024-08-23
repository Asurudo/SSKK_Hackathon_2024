#ifndef TAU
#define TAU PI*2
#endif

float3 Hash32(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 19.19);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}

float4 Disco(float2 uv)
{
    float v = abs(cos(uv.x * TAU) + cos(uv.y * TAU)) * 0.5;
    uv.x -= .5f;
    float3 cid2 = Hash32(float2(floor(uv.x - uv.y), floor(uv.x + uv.y)));
    return float4(cid2, v);
}

float4 StainedGlassLight(float2 uv, float speed)
{
    float t = _Time.y * speed;
    float2 stainedGlassUV = uv * 4. - float2(t, -t);
    float4 result = float4(1., 1., 1., 1.);

    for (int n = 1; n <= 4; n++)
    {
        stainedGlassUV /= n * .9;
        float4 d = Disco(stainedGlassUV);
        float curv = pow(d.a, .44 - ((1. / n) * 0.3));
        curv = pow(curv, .8 + (d.b * 2.));
        result *= clamp(d * curv, .35, 1.);
        stainedGlassUV += t * (n + .3);
    }
    result = clamp(result, 0., 1.);

    return result;
}

float4 Caustics(float2 uv,float speed)
{
    const int MaxIter = 5;

    float2 p = fmod(uv * TAU, TAU) - 250.;
    float2 i = float2(p);
    float val = 1.;
    float intensity = .005;
    for (int n = 0; n < MaxIter; n++)
    {
        float t = (_Time.y * speed) * (1.0f - (3.5 / float(n + 1)));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        val += 1. / length(float2(p.x / (sin(i.x + t) / intensity), p.y / (cos(i.y + t) / intensity)));
    }
    val /= float(MaxIter);
    val = 1.17 - pow(abs(val), 1.4);
    val = pow(abs(val), 8.);
    float4 result = float4(val, val, val, 1.);

    return result;
}