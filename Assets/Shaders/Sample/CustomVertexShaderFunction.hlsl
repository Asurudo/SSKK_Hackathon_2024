float3 CustomVertexShader(float4 Pos)
{
    float3 vertexPos = Pos.xyz;
    float3 output = (float3) 0;

            // yは変えないので始めの値を保持
    float keepY = vertexPos.y;
            
            // カメラに近いほど強く影響される 300までの範囲に影響
    float3 cameraPos = GetCameraPositionWS();
            // カメラとの距離をとる
    float weight = abs(sqrt(((vertexPos.x - cameraPos.x) * (vertexPos.x - cameraPos.x)) + ((vertexPos.y - cameraPos.y) * (vertexPos.y - cameraPos.y)) + ((vertexPos.z - cameraPos.z) * (vertexPos.z - cameraPos.z))));
            // とった値を0が1、300以遠で0になるようにする
    weight = (max((300 - weight), 0) / weight) * 0.5;

            // カメラと頂点のベクトルを取得
    float3 moveVec = float3(vertexPos.x - cameraPos.x, 0, vertexPos.z - cameraPos.z);
    moveVec = normalize(moveVec) * 10;

            // 移動
    output = lerp(vertexPos, vertexPos + (moveVec * (keepY / 100)), weight);

    output.y = keepY;

    return output;
}