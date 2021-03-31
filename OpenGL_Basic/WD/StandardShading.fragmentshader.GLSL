#version 330 core

// Interpolated values from the vertex shaders
in vec2 UV;
in vec3 Position_worldspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;
in vec3 LightDirection_tangentspace;
in vec3 EyeDirection_tangentspace;

// Ouput data
out vec4 color;

// Values that stay constant for the whole mesh.
uniform sampler2D DiffuseTextureSampler;
uniform sampler2D NormalTextureSampler;
uniform sampler2D SpecularTextureSampler;
uniform mat4 V;
uniform mat4 M;
uniform mat3 MV3x3;
uniform vec3 LightPosition_worldspace;
uniform float Image_width;
uniform float Image_height;

//filters
const mat3 SimpleBlur= (1.0/9.0)*mat3( 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 );
const mat3 SobelVert= mat3( 1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0 );
const mat3 SobelHorz= mat3( 1.0, 0.0, -1.0, 2.0, 0.0, -2.0, 1.0, 0.0, -1.0 );
const mat3 Sharpen= mat3( 0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0 );
const mat3 GaussianBlur= (1.0/16.0)*mat3( 1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0 );
const mat3 SimpleHorzEdge= mat3( 0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0, 0.0, 0.0 );
const mat3 SimpleVertEdge= mat3( 0.0, -3.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0 );
const mat3 ClearNone= mat3( 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0 );
//you can change the limits and delta to test the solutions of each one of the filters
const float limits = 1.0;
const float delta = 0.0; //you can increase delta in order to render a red zone 
						 //for example limits = 0.5 and delta = 0.4
void main(){
	// Light emission properties
	// You probably want to put them as uniforms
	vec4 LightColor = vec4(1,1,1,1);
	float LightPower = 40.0;

	// Material properties
	// vec3 MaterialDiffuseColor = texture( DiffuseTextureSampler, UV ).rgb;
	// vec3 MaterialAmbientColor = vec3(0.1,0.1,0.1) * MaterialDiffuseColor;

	// Local normal, in tangent space. V tex coordinate is inverted because normal map is in TGA (not in DDS) for better quality
	vec3 TextureNormal_tangentspace = normalize(texture( NormalTextureSampler, vec2(UV.x,-UV.y) ).rgb*2.0 - 1.0);

	// Distance to the light
	float distance = length( LightPosition_worldspace - Position_worldspace );
	// Normal of the computed fragment, in camera space
	vec3 n = TextureNormal_tangentspace;
	// Direction of the light (from the fragment to the light)
	vec3 l = normalize(LightDirection_tangentspace);
	// Cosine of the angle between the normal and the light direction, 
	// clamped above 0
	//  - light is at the vertical of the triangle -> 1
	//  - light is perpendicular to the triangle -> 0
	//  - light is behind the triangle -> 0
	float cosTheta = clamp( dot( n,l ), 0,1 );
	// Eye vector (towards the camera)
	vec3 E = normalize(EyeDirection_tangentspace);
	// Direction in which the triangle reflects the light
	vec3 R = reflect(-l,n);
	// Cosine of the angle between the Eye vector and the Reflect vector,
	// clamped to 0
	//  - Looking into the reflection -> 1
	//  - Looking elsewhere -> < 1
	float cosAlpha = clamp( dot( E,R ), 0,1 );

	vec4 MaterialDiffuseColor = vec4(0.0);
	vec4 MaterialAmbientColor = vec4(0.0);
	vec4 MaterialSpecularColor = texture( SpecularTextureSampler, UV ) * 0.8;
	if(UV.x <=limits)
	{
		vec3 sample;
		mat3 I, R, G, B;
		for (int i=0; i<3; i++)
		{
			for (int j=0; j<3; j++)
			{
				vec3 sample = texture( DiffuseTextureSampler, UV + vec2(i-1,j-1)/vec2(Image_width, Image_height) ).rgb;
				I[i][j] = length(sample); //intensity (or illumination)
				R[i][j] = sample.r; 
				G[i][j] = sample.g;
				B[i][j] = sample.b;  
			}
		}
		//apply the kernel convolution you can select any of defined ones or yoy can write your one and test
		//this is only for a 3 by 3 matrix of you need a bigger kernel you need to increase the filter size
		mat3 convolvedMatR = matrixCompMult( SimpleBlur, R);
		mat3 convolvedMatG = matrixCompMult( SimpleBlur, G);
		mat3 convolvedMatB = matrixCompMult( SimpleBlur, B);
		float convR = 0.0;
		float convG = 0.0;
		float convB = 0.0;
		//sum the result
		for (int i=0; i<3; i++)
		{
			for (int j=0; j<3; j++) 
			{
				convR += convolvedMatR[i][j];
				convG += convolvedMatG[i][j];
				convB += convolvedMatB[i][j];
			}
		}
		MaterialDiffuseColor = vec4(vec3(convR, convG, convB), 1.0);
		MaterialAmbientColor = vec4(0.1,0.1,0.1,1.0) * MaterialDiffuseColor;
	}
	else if(UV.x > (limits + delta))
	{
		MaterialDiffuseColor = texture(DiffuseTextureSampler, UV);
		MaterialAmbientColor = vec4(0.1,0.1,0.1,1.0) * MaterialDiffuseColor;
	}
	else // Draw a red line
	{
        MaterialDiffuseColor = vec4(1.0, 0.0, 0.0, 1.0);
		MaterialAmbientColor = vec4(0.1,0.1,0.1,1.0) * MaterialDiffuseColor;
	}
	color = 
		// Ambient : simulates indirect lighting
		MaterialAmbientColor +
		// Diffuse : "color" of the object
		MaterialDiffuseColor * LightColor * LightPower * cosTheta / (distance*distance) +
		// Specular : reflective highlight, like a mirror
		MaterialSpecularColor * LightColor * LightPower * pow(cosAlpha,5) / (distance*distance);
}