#include "Matrix3.h"
#include <cassert>
#include <cmath>
#include <sstream>
#include <stdexcept>
#include <tracy/Tracy.hpp>

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

Matrix3 Matrix3::Inverse() const
{
    ZoneScoped;
    Double det = m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
                 m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
                 m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
    if (det.isZero())
        throw std::runtime_error("Matrix is not invertible, determinant was " + det.ToString() +
                                 " for matrix: " + ToString());

    Double invDet = 1 / det;
    return Matrix3((m[1][1] * m[2][2] - m[1][2] * m[2][1]) * invDet,
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
    ZoneScoped;
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
    ZoneScoped;
    return Vector3(m.m[0][0] * v.x + m.m[0][1] * v.y + m.m[0][2] * v.z,
                   m.m[1][0] * v.x + m.m[1][1] * v.y + m.m[1][2] * v.z,
                   m.m[2][0] * v.x + m.m[2][1] * v.y + m.m[2][2] * v.z);
}
std::string Matrix3::ToString() const
{
    std::stringstream os;
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++) { os << m[i][j] << ';'; }
        os << '\n';
    }
    return os.str();
}
Vector3double Vector3double::operator+(Vector3double other)
{
    return { x + other.x, y + other.y, z + other.z };
}
Vector3double operator*(Matrix3double m, Vector3double v)
{
    return { m.m[0][0] * v.x + m.m[0][1] * v.y + m.m[0][2] * v.z,
             m.m[1][0] * v.x + m.m[1][1] * v.y + m.m[1][2] * v.z,
             m.m[2][0] * v.x + m.m[2][1] * v.y + m.m[2][2] * v.z };
}
double clamp(double val)
{
    ZoneScoped;
    if (val > 1) { return 1; }
    else if (val < -1) { return -1.0; }
    return val;
}
LatLngdouble Vector3double::ToLatLngImprecise() const
{
    ZoneScoped;
    double lat     = std::asin(z) / (2 * M_PI) * 360;
    double lon     = -1;
    double epsilon = 1e-6;
    if (std::abs(x) < epsilon && std::abs(y) < epsilon) { lon = 0; }
    else
    {
        double r2 = x * x + y * y + z * z;
        double s  = std::sqrt(r2 - z * z); // r^2-z^2 = x^2+y^2 >= 0
        if (std::abs(x) < epsilon)
        {
            if (y > 0) { lon = 0; }
            else { lon = 180; }
        }
        else
        {
            double inner = -x / s;
            inner        = clamp(inner);
            // lon          = asin(inner) / Constants::pi() * 180;
            lon = std::asin(inner) / (2 * M_PI) * 360;
            if (y < 0) { lon = 180 - lon; }
            if (lon > 180)
            {
                lon -= 360;
                assert(lon <= 180);
            }
        }
    }
    return LatLngdouble{ lat, lon };
}
