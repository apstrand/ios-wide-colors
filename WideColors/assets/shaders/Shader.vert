//
//  Shader.vsh
//  WideColors
//
//  Created by Peter Strand on 2017-01-10.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform mat4 u_transform;

varying mediump vec2 v_texCoord;

void main()
{
  v_texCoord = a_texCoord;
  gl_Position = u_transform * a_position;
}
