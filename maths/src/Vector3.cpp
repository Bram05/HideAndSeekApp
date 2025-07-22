#include "Vector3.h"
#include <cassert>
#include <iostream>

Vector3::Vector3(double x, double y, double z)
    : x{ Double(x) }
    , y{ Double(y) }
    , z{ Double(z) }
{
}

Vector3::Vector3(const Double& x, const Double& y, const Double& z)
    : x{ x }
    , y{ y }
    , z{ z }
{
}

Vector3::Vector3(const Vector3& other)
    : x{ other.x }
    , y{ other.y }
    , z{ other.z }
{
}

Vector3 NormalizedCrossProduct(const Vector3& a, const Vector3& b)
{
    Vector3 crossProduct = cross(a.normalized(), b.normalized());
    Double len           = crossProduct.length();
    if (len.isZero()) return Vector3(0, 0, 0); // Because of precision
    return crossProduct / len;
}

Vector3& Vector3::operator=(const Vector3& other)
{
    if (this != &other)
    {
        x = other.x;
        y = other.y;
        z = other.z;
    }
    return *this;
}
Vector3 operator+(const Vector3& a, const Vector3& b)
{
    return Vector3(a.x + b.x, a.y + b.y, a.z + b.z);
}
Vector3 operator-(const Vector3& a, const Vector3& b)
{
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
}
Vector3 operator*(const Vector3& a, const Double& b) { return Vector3(a.x * b, a.y * b, a.z * b); }
Vector3 operator/(const Vector3& a, const Double& b) { return Vector3(a.x / b, a.y / b, a.z / b); }

Double clamp(Double val)
{
    if (val > 1)
    {
        assert(val - Constants::epsilon <= 1);
        return 1;
    }
    else if (val < -1)
    {
        assert(val + Constants::epsilon >= -1);
        return -1.0;
    }
    return val;
}

Double GetDistanceAlongSphere(const Vector3& a, const Vector3& b)
{
    // we don't care if a and b are on the scale of the planet, or between -1 and 1
    Double inner = clamp(dot(a.normalized(), b.normalized()));
    // return math.acos(inner) / (2 * math.pi) * circumferenceEarth;
    return acos(inner) / (2 * Constants::pi());
}

LatLng Vector3::ToLatLng() const
{
    assert(length2().close(1));
    // Convert the vector to latitude and longitude
    Double lat = asin(z / length()) * (180 / Constants::pi());
    Double lon = Double(-1);
    if (x.isZero() && y.isZero())
    {
        lon = Double(0); // Arbitrary value when both x and y are zero
    }
    else
    {
        Double r2 = length2();
        Double s  = sqrt(r2 - z * z); // r^2-z^2 = x^2+y^2 >= 0
        if (x.isZero())
        {
            // This check is needed because we are outside the 'correct' domain of arcsin
            if (y > 0) { lon = 0; }
            else { lon = 180; }
        }
        else
        {
            Double inner = -x / s;
            inner        = clamp(inner);
            lon          = asin(inner) / Constants::pi() * 180;
            if (y < 0) { lon = 180 - lon; }
            if (lon > 180)
            {
                lon -= 360;
                std::cerr << "lon: " << lon.ToDouble() << '\n';
                assert(lon <= 180);
            }
        }
    }
    return LatLng(lat, lon);
}

Vector3 LatLng::ToVector3() const
{
    Double theta = longitudeInRad();
    Double phi   = latitudeInRad();
    return Vector3(-sin(theta) * cos(phi), cos(theta) * cos(phi), sin(phi));
}
std::ostream& operator<<(std::ostream& os, const Vector3& v)
{
    os << "Vector3(" << v.x << ", " << v.y << ", " << v.z << ")";
    return os;
}
std::ostream& operator<<(std::ostream& os, const LatLng& l)
{
    os << "LatLng(" << l.latitude << ", " << l.longitude << ")";
    return os;
}
