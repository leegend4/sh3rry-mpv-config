// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3.0 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library.

//!HOOK MAIN
//!SAVE discard

vec4 sample_pixel()
{
    return vec4(0);
}

//!HOOK SCALED
//!BIND HOOKED
//!BIND MAIN
//!SAVE DOWNSCALEDX
//!TRANSFORM 0.5 1.0 0.0 0.0
//!COMPONENTS 4

#define dxdy   (vec2(MAIN_pt.x, SCALED_pt.y))
#define ddxddy (SCALED_pt)

#define factor ((ddxddy*vec2(MAIN_size.x, SCALED_size.y))[axis])
#define GetFrom(tex, pos) (texture(tex, pos))

// -- Handles --
#define Get(pos)    (GetFrom(HOOKED, pos))

#define axis 0 //1st pass - 0, 2nd - 1

#define offset vec2(0,0)

#define Kernel(x) clamp(0.5 + (0.5 - abs(x)) / factor, 0.0, 1.0)
#define taps (1.0 + factor)

vec4 sample_pixel() {
    // Calculate bounds
    int low  = int(floor((SCALED_pos - 0.5*taps*dxdy) * SCALED_size - offset + vec2(0.5))[axis]);
    int high = int(floor((SCALED_pos + 0.5*taps*dxdy) * SCALED_size - offset + vec2(0.5))[axis]);

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = SCALED_pos;

    for (int k = 0; k &lt; high - low; k++) {
        pos[axis] = ddxddy[axis] * (float(k) + float(low) + 0.5);
        float rel = (pos[axis] - SCALED_pos[axis])*vec2(MAIN_size.x, SCALED_size.y)[axis] + offset[axis]*factor;
        float w = Kernel(rel);

        avg += vec4(w) * texture(SCALED, pos);
        W += w;
    }
    avg /= vec4(W);

    return avg;
}

//!HOOK SCALED
//!BIND HOOKED
//!BIND DOWNSCALEDX
//!BIND MAIN
//!SAVE DIFF
//!TRANSFORM 0.5 0.5 0.0 0.0
//!COMPONENTS 4

#define dxdy   (MAIN_pt)
#define ddxddy (DOWNSCALEDX_pt)

#define factor ((ddxddy*MAIN_size)[axis])
#define GetFrom(tex, pos) (texture(tex, pos))

// -- Handles --
#define Get(pos)    (GetFrom(HOOKED, pos))

#define axis 1 //1st pass - 0, 2nd - 1

#define offset vec2(0,0)

#define Kernel(x) clamp(0.5 + (0.5 - abs(x)) / factor, 0.0, 1.0)
#define taps (1.0 + factor)

#define Gamma(x)  ( mix(x * vec3(12.92), vec3(1.055) * pow(x, vec3(1.0/2.4)) - vec3(0.055), lessThanEqual(vec3(0.0031308), x)) )
#define Kb 0.0722
#define Kr 0.2126
#define Luma(rgb) ( dot(vec3(Kr, 1.0 - Kr - Kb, Kb), rgb) )

vec4 sample_pixel() {
    // Calculate bounds
    int low  = int(floor((DOWNSCALEDX_pos - 0.5*taps*dxdy) * DOWNSCALEDX_size - offset + vec2(0.5))[axis]);
    int high = int(floor((DOWNSCALEDX_pos + 0.5*taps*dxdy) * DOWNSCALEDX_size - offset + vec2(0.5))[axis]);

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = DOWNSCALEDX_pos;

    for (int k = 0; k &lt; high - low; k++) {
        pos[axis] = ddxddy[axis] * (float(k) + float(low) + 0.5);
        float rel = (pos[axis] - DOWNSCALEDX_pos[axis])*MAIN_size[axis] + offset[axis]*factor;
        float w = Kernel(rel);

        avg += vec4(w) * texture(DOWNSCALEDX, pos);
        W += w;
    }
    avg /= vec4(W);

    //return avg;
    return vec4(Gamma(avg.xyz) - texture(MAIN, MAIN_pos).xyz, Luma(avg.xyz));
}

//!HOOK SCALED
//!BIND HOOKED
//!BIND DIFF

#define FinalPass 1

#define strength  1.0
#define softness  0.0

// -- Edge detection options -- 
#define acuity 6.0
#define radius 0.5
#define power 1.0

// -- Skip threshold --
#define threshold 1
#define skip (1==0)//(c0.a &lt; threshold/255.0);

#define dxdy (HOOKED_pt)
#define ddxddy (DIFF_pt)

// -- Window Size --
#define taps 4.0
#define even (taps - 2.0 * (taps / 2.0) == 0.0)
#define minX int(1.0-ceil(taps/2.0))
#define maxX int(floor(taps/2.0))

#define factor (ddxddy*HOOKED_size)
#define Kernel(x) (cos(acos(-1.0)*(x)/taps)) // Hann kernel

// -- Convenience --
#define sqr(x) dot(x,x)

// -- Input processing --
//Current high res value
#define Get(x,y)     (texture(tex,   HOOKED_pos + sqrt(ddxddy*HOOKED_size)*dxdy*vec2(x,y)).xyz)
#define GetY(x,y)    (texture(DIFF,  ddxddy*(p+vec2(x,y)+0.5)).a)
//Downsampled result
#define Diff(x,y)    (texture(DIFF,  ddxddy*(p+vec2(x,y)+0.5)).xyz)

//#define Gamma(x)   ( all(lessThan(x, vec3(0.018))) ? x * 4.506198600878514 : 1.099 * pow(x, vec3(0.45)) - 0.099 )
//#define GammaInv(x)( all(lessThan(x, vec3(0.018 * 4.506198600878514))) ? x / 4.506198600878514 : pow((x + 0.099) / 1.099, vec3(1.0 / 0.45)) )
#define Gamma(x)     ( mix(x * vec3(12.92), vec3(1.055) * pow(x, vec3(1.0/2.4)) - vec3(0.055), lessThanEqual(vec3(0.0031308), x)) )
#define GammaInv(x)  ( mix(x / vec3(12.92), pow((x + vec3(0.055))/vec3(1.055), vec3(2.4)), lessThan(vec3(0.04045), x)) )
#define Kb 0.0722
#define Kr 0.2126
#define Luma(rgb)  ( dot(vec3(Kr, 1.0 - Kr - Kb, Kb), rgb) )

vec4 sample_pixel() {    
    vec4 c0 = texture(HOOKED, HOOKED_pos);
    if (DIFF_size.y &gt;= HOOKED_size.y) return c0;
    vec3 Lin = c0.xyz;
    c0.xyz = Gamma(c0.xyz);

    // Calculate position
    vec2 p = HOOKED_pos * DIFF_size.xy - vec2(0.5);
    vec2 offset = p - (even ? floor(p) : round(p));
    p -= offset;

    // Calculate faithfulness force
    float weightSum = 0.0;
    vec3 diff = vec3(0);
    vec3 soft = vec3(0);

    for (int X = minX; X &lt;= maxX; X++)
    for (int Y = minX; Y &lt;= maxX; Y++)
    {
        float dI2 = sqr(acuity*(Luma(c0.xyz) - GetY(X,Y)));
        //float dXY2 = sqr((vec2(X,Y) - offset)/radius);
        //float weight = exp(-0.5*dXY2) * pow(1.0 + dI2/power, - power);
        vec2 krnl = Kernel(vec2(X,Y) - offset);
        float weight = krnl.x * krnl.y * pow(1.0 + dI2/power, - power);

        diff += weight*Diff(X,Y);
        weightSum += weight;
    }
    diff /= weightSum;
    c0.xyz -= strength * diff;

    // Convert back to linear light;
    c0.xyz = GammaInv(c0.xyz);

#ifndef FinalPass

    #if softness != 0.0
        weightSum=0.0;
        #define softAcuity 6.0

        for (int X = -1; X &lt;= 1; X++)
        for (int Y = -1; Y &lt;= 1; Y++)
        if (X != 0 || Y != 0)
        {
            vec3 dI = Get(X,Y) - Lin;
            float dI2 = sqr(softAcuity*dI);
            float dXY2 = sqr(vec2(X,Y)/radius);
            float weight = pow(inversesqrt(dXY2 + dI2),3.0); // Fundamental solution to the 5d Laplace equation
            // float weight = exp(-0.5*dXY2) * pow(1 + dI2/power, - power);

            soft += vec3(weight * dI);
            weightSum += weight;
        }
        soft /= vec3(weightSum);

        c0.xyz += vec3(softness) * soft;
    #endif
#else
    c0.a = 1.0;
#endif

    return c0;
}