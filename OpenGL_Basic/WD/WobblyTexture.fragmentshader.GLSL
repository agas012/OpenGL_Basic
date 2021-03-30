#version 330 core

in vec2 UV;

out vec3 color;

uniform sampler2D renderedTexture;
uniform float time;

void main(){
	vec3 temp = texture( renderedTexture, UV+ 0.005*vec2( sin(time+1024.0*UV.x),cos(time+768.0*UV.y)) ).xyz ;
	// float norm = (temp.x + temp.y + temp.z)/3.0;
	// if (norm<=0.5)
	// 	{
	// 	temp.x=0;
	// 	temp.y=0;
	// 	temp.z=0;
	// 	//norm=0;	
	// 	}
		
	color = temp;
}