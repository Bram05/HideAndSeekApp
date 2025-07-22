#include "Matrix3.h"
#include <stdexcept>

Matrix3 Matrix3::RotationX(Double angle)
{
    Double c = cos(angle);
    Double s = sin(angle);
    return Matrix3(1, 0, 0, 0, c, -s, 0, s, c);
}

Matrix3 Matrix3::RotationY(Double angle)
{
    Double c = cos(angle);
    Double s = sin(angle);
    return Matrix3(c, 0, -s, 0, 1, 0, s, 0, c);
}

Matrix3 Matrix3::RotationZ(Double angle)
{
    Double c = cos(angle);
    Double s = sin(angle);
    return Matrix3(c, -s, 0, s, c, 0, 0, 0, 1);
}

Matrix3 Matrix3::Invert() const
{
	Double det = m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
				 m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
				 m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
	if (det.isZero()) throw std::runtime_error("Matrix is not invertible");

	Double invDet = 1 / det;
	return Matrix3(
		(m[1][1] * m[2][2] - m[1][2] * m[2][1]) * invDet,
		(m[0][2] * m[2][1] - m[0][1] * m[2][2]) * invDet,
		(m[0][1] * m[1][2] - m[0][2] * m[1][1]) * invDet,
		(m[1][2] * m[2][0] - m[1][0] * m[2][2]) * invDet,
		(m[0][0] * m[2][2] - m[0][2] * m[2][0]) * invDet,
		(m[0][2] * m[1][0] - m[0][0] * m[1][2]) * invDet,
		(m[1][0] * m[2][1] - m[1][1] * m[2][0]) * invDet,
		(m[0][1] * m[2][0] - m[0][0] * m[2][1]) * invDet,
		(m[0][0] * m[1][1] - m[0][1] * m[1][0]) * invDet);
}

Matrix3 operator*(const Matrix3& a, const Matrix3& b)
{
    Matrix3 result(0, 0, 0, 0, 0, 0, 0, 0, 0);
    for (int i = 0; i < 3; ++i)
    {
        for (int j = 0; j < 3; ++j)
        {
            for (int k = 0; k < 3; ++k) { result.m[i][j] += a.m[i][k] * b.m[k][j]; }
        }
    }
    return result;
}

Vector3 operator*(const Matrix3& m, const Vector3& v)
{
    return Vector3(m.m[0][0] * v.x + m.m[0][1] * v.y + m.m[0][2] * v.z,
                   m.m[1][0] * v.x + m.m[1][1] * v.y + m.m[1][2] * v.z,
                   m.m[2][0] * v.x + m.m[2][1] * v.y + m.m[2][2] * v.z);
}
