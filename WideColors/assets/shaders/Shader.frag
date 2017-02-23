//
//  Shader.fsh
//  WideColors
//
//  Created by Peter Strand on 2017-01-10.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

precision mediump float;

uniform sampler2D u_sampler;

varying mediump vec2 v_texCoord;

void main()
{
  gl_FragColor = texture2D(u_sampler, v_texCoord);
}
