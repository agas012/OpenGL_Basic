#version 330 core

// Interpolated values from the vertex shaders
in vec2 UV;
in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

// Ouput data
out vec4 color;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;
uniform float Image_width;
uniform float Image_height;

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
	vec4 sum = vec4(0.0);
	if(UV.x <=limits)
	{
		vec3 sample;
		mat3 I, R, G, B;
		for (int i=0; i<3; i++)
		{
			for (int j=0; j<3; j++)
			{
				vec3 sample = texture( myTextureSampler, UV + vec2(i-1,j-1)/vec2(Image_width, Image_height) ).rgb;
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
		sum = vec4(vec3(convR, convG, convB), 1.0);
	}
	else if(UV.x > (limits + delta))
	{
		sum = texture(myTextureSampler, UV);
	}
	else // Draw a red line
	{
        sum = vec4(1.0, 0.0, 0.0, 1.0);
	}
	color = sum;
}