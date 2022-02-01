# NvidiaPrecisionLossPoc
Proof of concept that demonstrates precision loss in certain vertex shader instructions on NVIDIA graphics cards.

## Problem Description
Compiling two shaders that perform the same calculation using different shader instructions can lead to different outputs for the same inputs due to precision loss. When the calculations for transforming a vertex position in a vertex shader experience this precision loss it can cause certain depth tests to fail and result in z-fighting in the output image. This behavior has been observed on multiple NVIDIA graphics cards but does not happen on AMD graphics cards.

![](/Images/amd_vs_nvidia.png)

## Root Cause
When compiling HLSL shaders the shader compiler can emit different instructions for the same operations depending on other conditions during compilation. This was observed when compiling two vertex shaders that transform a vertex position using the same calculations, but had different microcode instructions emitted as a result of the shader optimizer choosing different optimizations. Given the following code snippets:
```
float dph(float3 a, float4 b)
{
	return (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + b.w;
}

...

output.Pos.x = dph(Pos, WorldViewProjection1);
output.Pos.y = dph(Pos, WorldViewProjection2);
output.Pos.z = dph(Pos, WorldViewProjection3);
output.Pos.w = dph(Pos, WorldViewProjection4);
```

The shader compiler can emit two different implementations for the "dph" function which will produce different outputs give the same inputs. The first implementation uses add/mul/mad instructions:
```
   3: mul r0.w, r0.x, r1.x
   4: mul r1.x, r0.y, r1.y
   5: add r0.w, r0.w, r1.x
   6: mul r1.x, r0.z, r1.z
   7: add r0.w, r0.w, r1.x
   8: add r0.w, r1.w, r0.w
```

While the second implementation uses dp3/add instructions:
```
   3: dp3 r0.w, r0.xyzx, r1.xyzx
   4: add r0.w, r1.w, r0.w
```

The output of these two implementations when given the same inputs differs by ~0.000000002. This may not seem significant but in certain configurations when using a depth test of D3D11_COMPARISON_EQUAL this will cause the depth test to fail and z-fighting to occur. 

![](/Images/depth_test.png)

This was originally found in a much larger d3d application where the same mesh pieces are rendered multiple times on different shader passes. Two different vertex shaders were being used to render both of the passes and had the exact same HLSL code for transforming the vertex positions. However, the resulting microcode emitted for the "dph" function had two different implementations which produced slightly different outputs. Using this information I was able to create a minimized poc of the issue. For a full write up of how I originally found and diagnosed the issue see: [Diagnosing Precision Loss on NVIDIA Graphics Cards](https://icode4.coffee/?p=566).

## How the poc works
This minimized proof of concept is a modified version of one of the D3D11 sample applications that renders a spinning cube. It has been modified to render the same cube twice using different configurations for each pass. The shaders used have two different implementations for the "dph" function based on the output I observed in a much larger d3d application for the same HLSL code, depending on what optimizations the shader compiler applied. 

**Pass 1:** The cube is drawn in the color red with the depth test comparison function set to D3D11_COMPARISON_GREATER_EQUAL.

**Pass 2:** The cube is drawn in the color green with the depth test comparison function set to D3D11_COMPARISON_EQUAL.

The expected outcome is that the depth test will always pass on the second pass and the cube will always appear green. However, due to the precision loss in the outputs from the two different implementations of the "dph" function the depth test will periodically fail and cause the red cube to z-fight with the green cube.

![](/Images/z-fighting.png)

Testing this on NVIDIA graphics cards results in periodic z-fighting of the red cube (precision loss). Testing this on AMD graphics cards results in the cube always being green and no z-fighting occuring (no precision loss). Graphics cards tested:
- NVIDIA RTX 3080 – cube flickers (precision loss)
- NVIDIA RTX 2060 – cube flickers
- AMD RX 580 – no flickering (no precision loss)
- AMD RX 5700 XT – no flickering
