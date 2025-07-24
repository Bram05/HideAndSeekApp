#pragma once

#include "Double.h"
#include "Vector3.h"

class Matrix3
{
public:
    Double m[3][3];

    Matrix3(const Double& m00, const Double& m01, const Double& m02, const Double& m10,
            const Double& m11, const Double& m12, const Double& m20, Double m21, Double m22)
        : m{ { m00, m01, m02 }, { m10, m11, m12 }, { m20, m21, m22 } }
    {
    }
    Matrix3(const Vector3& a, const Vector3& b, const Vector3& c)
        : m{ { a.x, b.x, c.x }, { a.y, b.y, c.y }, { a.z, b.z, c.z } }
    {
    }

    Matrix3 Inverse() const;
    std::string ToString() const;

    static Matrix3 RotationX(Double angle);
    static Matrix3 RotationY(Double angle);
    static Matrix3 RotationZ(Double angle);

    friend Matrix3 operator*(const Matrix3& a, const Matrix3& b);
    friend Double operator*(const Matrix3& m, const Double& v)
    {
        return m.m[0][0] * v + m.m[0][1] * v + m.m[0][2] * v;
    }
    friend Vector3 operator*(const Matrix3& m, const Vector3& v);
};
