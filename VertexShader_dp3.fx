//--------------------------------------------------------------------------------------
// File: Tutorial04.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
cbuffer ConstantBuffer : register( b0 )
{
    float4 WorldViewProjection1;
    float4 WorldViewProjection2;
    float4 WorldViewProjection3;
    float4 WorldViewProjection4;

    float4 ColorOverride;
}

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Pos : SV_POSITION;
    float4 Color : COLOR0;
};

float dph(float4 a, float4 b)
{
    return dot(a.xyz, b.xyz) + b.w;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(float4 Pos : POSITION, float4 Color : COLOR )
{
    VS_OUTPUT output = (VS_OUTPUT)0;

    output.Pos.x = dph(Pos, WorldViewProjection1);
    output.Pos.y = dph(Pos, WorldViewProjection2);
    output.Pos.z = dph(Pos, WorldViewProjection3);
    output.Pos.w = dph(Pos, WorldViewProjection4);

    output.Color = ColorOverride;

    return output;
}