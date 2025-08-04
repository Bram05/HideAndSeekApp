#include "Vector3.h"
#include "Constants.h"
#include "Matrix3.h"
#include <cassert>
#include <cmath>
#include <iostream>
#include <sstream>
#include <tracy/Tracy.hpp>

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

Vector3 cross(const Vector3& a, const Vector3& b)
{
    ZoneScoped;
    Double x = a.y * b.z;
    x -= a.z * b.y;
    Double y = a.z * b.x;
    y -= a.x * b.z;
    Double z = a.x * b.y;
    z -= a.y * b.x;
    return Vector3(x, y, z);
    // return Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
}

Vector3 NormalizedCrossProduct(const Vector3& a, const Vector3& b)
{
    ZoneScoped;
    // Vector3 crossProduct = cross(a.normalized(), b.normalized());
    Vector3 crossProduct = cross(a, b);
    // Double len = crossProduct.length();
    // std::cerr << "length is " << len << '\n';
    if (crossProduct.isZero()) return Vector3(0, 0, 0); // Because of precision
    return crossProduct.normalized();
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

Double clamp(const Double& val)
{
    ZoneScoped;
    if (val > 1)
    {
        // std::cerr << "WARNING: clamping value " << val << '\n';
        assert(val - Constants::GetEpsilon() <= 1);
        return 1;
    }
    else if (val < -1)
    {
        // std::cerr << "WARNING: clamping value " << val << '\n';
        assert(val + Constants::GetEpsilon() >= -1);
        return -1.0;
    }
    return val;
}
double clampImprecise(double val)
{
    ZoneScoped;
    if (val > 1)
    {
        // assert(val - Constants::GetEpsilon() <= 1);
        return 1;
    }
    else if (val < -1)
    {
        // assert(val + Constants::GetEpsilon() >= -1);
        return -1.0;
    }
    return val;
}

Double GetDistanceAlongEarth(const Vector3& a, const Vector3& b)
{
    ZoneScoped;
    // we don't care if a and b are on the scale of the planet, or between -1 and 1
    // Double inner = clamp(dot(a.normalized(), b.normalized()));
    Double inner = clamp(dot(a, b));
    // return math.acos(inner) / (2 * math.pi) * circumferenceEarth;
    return acos(inner) / (2 * Constants::pi()) * Constants::CircumferenceEarth();
}
double GetDistanceAlongEarthImprecise(const Vector3double& a, const Vector3double& b)
{
    ZoneScoped;
    // we don't care if a and b are on the scale of the planet, or between -1 and 1
    // Double inner = clamp(dot(a.normalized(), b.normalized()));
    double inner = clampImprecise(a.x * b.x + a.y * b.y + a.z * b.z);
    // return math.acos(inner) / (2 * math.pi) * circumferenceEarth;
    return std::acos(inner) / (2 * M_PI) * Constants::CircumferenceEarthImprecise();
}

LatLng Vector3::ToLatLng() const
{
    ZoneScopedS(20);
    // if (length2() != 1)
    // {
    //     std::cerr << *this << ", " << length() << '\n';
    //     assert(false);
    // }
    // Convert the vector to latitude and longitude
    // Double lat = asin(z / length()) * ("180" / Constants::pi());
    assert(length() == 1);
    // Double lat = asinu(z / length());
    Double lat = asinu(z);
    Double lon = -1;
    if (x.isZero() && y.isZero())
    {
        // lon = Double(0); // Arbitrary value when both x and y are zero
        lon = 0;
    }
    else
    {
        Double r2 = length2();
        Double s  = sqrt(r2 - sqr(z)); // r^2-z^2 = x^2+y^2 >= 0
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
            // lon          = asin(inner) / Constants::pi() * 180;
            lon = asinu(inner);
            if (y < 0) { lon = 180 - lon; }
            if (lon > 180)
            {
                lon -= 360;
                assert(lon <= 180);
            }
        }
    }
    return LatLng(lat, lon);
}

Vector3 LatLng::ToVector3() const
{
    ZoneScoped;
    return Vector3(-sinu(longitude) * cosu(latitude), cosu(longitude) * cosu(latitude),
                   sinu(latitude));
}
std::ostream& operator<<(std::ostream& os, const Vector3& v) { return os << v.ToString(); }
std::ostream& operator<<(std::ostream& os, const LatLng& l) { return os << l.ToString(); }
std::string LatLng::ToString() const
{
    std::stringstream s;
    s << "LatLng(" << latitude << ", " << longitude << ")";
    return s.str();
}
std::string Vector3::ToString() const
{
    std::stringstream os;
    os << "Vector3(" << x << ", " << y << ", " << z << ")";
    return os.str();
}
