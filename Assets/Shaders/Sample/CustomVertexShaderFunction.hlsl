float3 CustomVertexShader(float4 Pos)
{
    float3 vertexPos = Pos.xyz;
    float3 output = (float3) 0;

            // y�͕ς��Ȃ��̂Ŏn�߂̒l��ێ�
    float keepY = vertexPos.y;
            
            // �J�����ɋ߂��قǋ����e������� 300�܂ł͈̔͂ɉe��
    float3 cameraPos = GetCameraPositionWS();
            // �J�����Ƃ̋������Ƃ�
    float weight = abs(sqrt(((vertexPos.x - cameraPos.x) * (vertexPos.x - cameraPos.x)) + ((vertexPos.y - cameraPos.y) * (vertexPos.y - cameraPos.y)) + ((vertexPos.z - cameraPos.z) * (vertexPos.z - cameraPos.z))));
            // �Ƃ����l��0��1�A300�ȉ���0�ɂȂ�悤�ɂ���
    weight = (max((300 - weight), 0) / weight) * 0.5;

            // �J�����ƒ��_�̃x�N�g�����擾
    float3 moveVec = float3(vertexPos.x - cameraPos.x, 0, vertexPos.z - cameraPos.z);
    moveVec = normalize(moveVec) * 10;

            // �ړ�
    output = lerp(vertexPos, vertexPos + (moveVec * (keepY / 100)), weight);

    output.y = keepY;

    return output;
}