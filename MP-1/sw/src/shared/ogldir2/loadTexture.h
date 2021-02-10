#ifndef LOADTEXTURE_H
#define LOADTEXTURE_H

#include <GL/glew.h>
#include <IL/il.h>
#include <iostream>

GLuint loadTexture(const  char* theFileName)
{
	GLuint textureID;			// Create a texture ID as a GLuint
	ILuint imageID;				// Create an image ID as a ULuint
	ilInit();   //��ʼ��IL
	ilGenImages(1, &imageID); 		// Generate the image ID
	ilBindImage(imageID); 			// Bind the image
	ILboolean success = ilLoadImage(theFileName); 	// Load the image file

	if (success) 
	{
		glGenTextures(1, &textureID); //����Opengl����ӿ�
		glBindTexture(GL_TEXTURE_2D, textureID);

		//��������Ĺ��˺ͻ���ģʽ
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

		//�����ص���������ת��ΪOpenGL��ʽ
 	    ilConvertImage(IL_RGBA, IL_UNSIGNED_BYTE);
		//�����ݴ������������
		glTexImage2D(GL_TEXTURE_2D, 				// Type of texture
					 0,				// Pyramid level (for mip-mapping) - 0 is the top level
					 ilGetInteger(IL_IMAGE_FORMAT),	// Internal pixel format to use. Can be a generic type like GL_RGB or GL_RGBA, or a sized type
					 ilGetInteger(IL_IMAGE_WIDTH),	// Image width
					 ilGetInteger(IL_IMAGE_HEIGHT),	// Image height
					 0,				// Border width in pixels (can either be 1 or 0)
					 ilGetInteger(IL_IMAGE_FORMAT),	// Format of image pixel data
					 GL_UNSIGNED_BYTE,		// Image data type
					 ilGetData());			// The actual image data itself
 	}
	else 
		std::cout << "Fail to load the texture!" << std::endl;
 
 	ilDeleteImages(1, &imageID); // Because we have already copied image data into texture data we can release memory used by image.
	std::cout << "Texture creation successful." << std::endl;
	return textureID; // ���ؼ�����������
}


GLuint loadTexture(const  char* theFileName, GLuint target)
{
	GLuint textureID;			// Create a texture ID as a GLuint
	ILuint imageID;				// Create an image ID as a ULuint
	ilInit();   //��ʼ��IL
	ilGenImages(1, &imageID); 		// Generate the image ID
	ilBindImage(imageID); 			// Bind the image
	ILboolean success = ilLoad(IL_DDS,theFileName); 	// Load the image file

	if (success) {
		glGenTextures(1, &textureID); //����Opengl����ӿ�
		glBindTexture(target, textureID);
		//��������Ĺ��˺ͻ���ģʽ
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		//�����ص���������ת��ΪOpenGL��ʽ
		ilConvertImage(IL_RGBA, IL_UNSIGNED_BYTE);
		//�����ݴ������������

		switch (target)
		{
		case GL_TEXTURE_1D:
			glTexImage1D(GL_TEXTURE_1D, 0,ilGetInteger(IL_IMAGE_FORMAT),ilGetInteger(IL_IMAGE_WIDTH),	
				         0, ilGetInteger(IL_IMAGE_FORMAT), GL_UNSIGNED_BYTE,ilGetData());	
			break;
		case GL_TEXTURE_2D:
			glTexImage2D(GL_TEXTURE_2D, 				// Type of texture
				0,				// Pyramid level (for mip-mapping) - 0 is the top level
				ilGetInteger(IL_IMAGE_FORMAT),	// Internal pixel format to use. Can be a generic type like GL_RGB or GL_RGBA, or a sized type
				ilGetInteger(IL_IMAGE_WIDTH),	// Image width
				ilGetInteger(IL_IMAGE_HEIGHT),	// Image height
				0,				// Border width in pixels (can either be 1 or 0)
				ilGetInteger(IL_IMAGE_FORMAT),	// Format of image pixel data
				GL_UNSIGNED_BYTE,		// Image data type
				ilGetData());			// The actual image data itself
			break;
		case GL_TEXTURE_3D:
			glTexImage3D(GL_TEXTURE_3D, 				// Type of texture
				0,				// Pyramid level (for mip-mapping) - 0 is the top level
				ilGetInteger(IL_IMAGE_FORMAT),	// Internal pixel format to use. Can be a generic type like GL_RGB or GL_RGBA, or a sized type
				ilGetInteger(IL_IMAGE_WIDTH),	// Image width
				ilGetInteger(IL_IMAGE_HEIGHT),	// Image height
				ilGetInteger(IL_IMAGE_DEPTH),
				0,				// Border width in pixels (can either be 1 or 0)
				ilGetInteger(IL_IMAGE_FORMAT),	// Format of image pixel data
				GL_UNSIGNED_BYTE,		// Image data type
				ilGetData());			// The actual image data itself
			break;
		/*case GL_TEXTURE_1D_ARRAY:
			glTexStorage2D(GL_TEXTURE_1D_ARRAY, h.miplevels, h.glinternalformat, h.pixelwidth, h.arrayelements);
			glTexSubImage2D(GL_TEXTURE_1D_ARRAY, 0, 0, 0, h.pixelwidth, h.arrayelements, h.glformat, h.gltype, data);
			break;
		case GL_TEXTURE_2D_ARRAY:
			glTexStorage3D(GL_TEXTURE_2D_ARRAY, h.miplevels, h.glinternalformat, h.pixelwidth, h.pixelheight, h.arrayelements);
			glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, 0, h.pixelwidth, h.pixelheight, h.arrayelements, h.glformat, h.gltype, data);
			break;
			*/
			glTexImage3D(GL_TEXTURE_3D, 				// Type of texture
				0,				// Pyramid level (for mip-mapping) - 0 is the top level
				ilGetInteger(IL_IMAGE_FORMAT),	// Internal pixel format to use. Can be a generic type like GL_RGB or GL_RGBA, or a sized type
				ilGetInteger(IL_IMAGE_WIDTH),	// Image width
				ilGetInteger(IL_IMAGE_HEIGHT),	// Image height
				ilGetInteger(IL_IMAGE_DEPTH),
				0,				// Border width in pixels (can either be 1 or 0)
				ilGetInteger(IL_IMAGE_FORMAT),	// Format of image pixel data
				GL_UNSIGNED_BYTE,		// Image data type
				ilGetData());			// The actual image data itself
		case GL_TEXTURE_CUBE_MAP:
			glTexStorage2D(GL_TEXTURE_CUBE_MAP, 0, ilGetInteger(IL_IMAGE_FORMAT),
				           ilGetInteger(IL_IMAGE_WIDTH), ilGetInteger(IL_IMAGE_HEIGHT));
			// glTexSubImage3D(GL_TEXTURE_CUBE_MAP, 0, 0, 0, 0, h.pixelwidth, h.pixelheight, h.faces, h.glformat, h.gltype, data);
			{
				for (unsigned int i = 0; i < 6; i++)
					glTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, ilGetInteger(IL_IMAGE_WIDTH),	// Image width
					ilGetInteger(IL_IMAGE_WIDTH),	// Image width
					ilGetInteger(IL_IMAGE_HEIGHT),	// Image height
					0,
					0,				// Border width in pixels (can either be 1 or 0)
					ilGetInteger(IL_IMAGE_FORMAT),	// Format of image pixel data
					GL_UNSIGNED_BYTE, ilGetData() + 6 * i);
			}
			break;
		//case GL_TEXTURE_CUBE_MAP_ARRAY:
		//	glTexStorage3D(GL_TEXTURE_CUBE_MAP_ARRAY, h.miplevels, h.glinternalformat, h.pixelwidth, h.pixelheight, h.arrayelements);
		//	glTexSubImage3D(GL_TEXTURE_CUBE_MAP_ARRAY, 0, 0, 0, 0, h.pixelwidth, h.pixelheight, h.faces * h.arrayelements, h.glformat, h.gltype, data);
		//	break;
		default:                                               // Should never happen
			break;
		}
	}
	else 
		std::cout << "Fail to load the texture!" << std::endl;
 
 	ilDeleteImages(1, &imageID); // Because we have already copied image data into texture data we can release memory used by image.
	std::cout << "Texture creation successful." << std::endl;
	return textureID; // ���ؼ�����������
}
#endif