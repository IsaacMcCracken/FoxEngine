package fox_math

import lin "core:math/linalg/glsl"

TAU :: 6.28318530717958647692528676655900576
PI  :: 3.14159265358979323846264338327950288
E   :: 2.71828182845904523536
τ   :: TAU
π   :: PI
e   :: E

SQRT_TWO   :: 1.41421356237309504880168872420969808
SQRT_THREE :: 1.73205080756887729352744634150587236
SQRT_FIVE  :: 2.23606797749978969640917366873127623

LN2  :: 0.693147180559945309417232121458176568
LN10 :: 2.30258509299404568401799145468436421

F32_EPSILON :: 1e-7

vec2 :: lin.vec2
vec3 :: lin.vec3
vec4 :: lin.vec4

mat2 :: lin.mat2
mat3 :: lin.mat4
mat4 :: lin.mat4

quat :: lin.quat
plane :: vec4

Transform :: struct {
	position: vec3,
	scale: vec3,
	orientation: quat
}


dot :: proc{
	lin.dot_vec2, 
  lin.dot_vec3, 
  lin.dot_vec4,
	lin.dot_quat,
}

length :: proc{
	lin.length_vec2,
  lin.length_vec3,
  lin.length_vec4,
	lin.length_quat,
}

length_sqr :: proc{
	length_sqr_vec2,
  length_sqr_vec3,
  length_sqr_vec4,
}

cos :: proc{
	lin.cos_f32,
	lin.cos_vec2,
	lin.cos_vec3,
	lin.cos_vec4,
}

sin :: proc{
	lin.sin_f32,
	lin.sin_vec2,
	lin.sin_vec3,
	lin.sin_vec4,
}

tan :: proc{
	lin.tan_f32,
	lin.tan_vec2,
	lin.tan_vec3,
	lin.tan_vec4,
}

acos :: proc{
	lin.acos_f32,
	lin.acos_vec2,
	lin.acos_vec3,
	lin.acos_vec4,
}

asin :: proc{
	lin.asin_f32,
	lin.asin_vec2,
	lin.asin_vec3,
	lin.asin_vec4,
}

atan :: proc{
	lin.atan_f32,
	lin.atan_vec2,
	lin.atan_vec3,
	lin.atan_vec4,
}

atan2 :: proc{
	lin.atan2_f32,
	lin.atan2_vec2,
	lin.atan2_vec3,
	lin.atan2_vec4,
}

sqrt :: proc{
	lin.sqrt_f32,
	lin.sqrt_vec2,
	lin.sqrt_vec3,
	lin.sqrt_vec4,
}

rsqrt :: inverse_sqrt
inverse_sqrt :: proc{
	lin.inversesqrt_f32,
	lin.inversesqrt_vec2,
	lin.inversesqrt_vec3,
	lin.inversesqrt_vec4,
}


pow :: proc{
	lin.pow_f32,
	lin.pow_vec2,
	lin.pow_vec3,
	lin.pow_vec4,
}

exp :: proc{
	lin.exp_f32,
	lin.exp_vec2,
	lin.exp_vec3,
	lin.exp_vec4,
}

log :: proc{
	lin.log_f32,
	lin.log_vec2,
	lin.log_vec3,
	lin.log_vec4,
}

exp2 :: proc{
	lin.exp2_f32,
	lin.exp2_vec2,
	lin.exp2_vec3,
	lin.exp2_vec4,
}

floor :: proc{
	lin.floor_f32,
	lin.floor_vec2,
	lin.floor_vec3,
	lin.floor_vec4,
}

round :: proc{
	lin.round_f32,
	lin.round_vec2,
	lin.round_vec3,
	lin.round_vec4,
}

ceil:: proc{
	lin.ceil_f32,
	lin.ceil_vec2,
	lin.ceil_vec3,
	lin.ceil_vec4,
}

mod :: proc{
	lin.mod_f32,
	lin.mod_vec2,
	lin.mod_vec3,
	lin.mod_vec4,
}

normalize :: proc{
	lin.normalize_f32,
	lin.normalize_vec2,
	lin.normalize_vec3,
	lin.normalize_vec4,
	lin.normalize_quat,
}

cross :: proc{lin.cross_vec3}

inverse :: proc{
	lin.inverse_mat2, 
	lin.inverse_mat3, 
	lin.inverse_mat4,
	lin.inverse_quat,
}

perspective :: proc{
	lin.mat4Perspective,
}

look_at :: proc{
	lin.mat4LookAt,
}

translate :: proc{
	lin.mat4Translate,
}

scale :: proc{
	lin.mat4Scale,
}

rotate :: proc{
	lin.mat4Rotate,
}

mat_from_quat :: proc{
	lin.mat4FromQuat,
}

quat_axis_angle :: proc{lin.quatAxisAngle}

determinant :: proc{lin.determinant_matrix2x2, lin.determinant_matrix3x3, lin.determinant_matrix4x4,}

@(require_results) length_sqr_vec2 :: proc(v: vec2) -> f32 {
	return dot(v, v)
}

@(require_results) length_sqr_vec3 :: proc(v: vec3) -> f32 {
	return dot(v, v)
}

@(require_results) length_sqr_vec4 :: proc(v: vec4) -> f32 {
	return dot(v, v)
}

@(require_results) mat_from_transform :: proc(transform: Transform) -> mat4 {
	return translate(transform.position) * mat_from_quat(transform.orientation) * scale(transform.scale)
}