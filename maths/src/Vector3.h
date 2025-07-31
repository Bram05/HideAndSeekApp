#pragma once
#include "Constants.h"
#include "Double.h"
#include <tracy/Tracy.hpp>

class LatLng;
struct LatLngdouble
{
    double latitude, longitude;
};
class Vector3
{
public:
    Vector3() {}
    Vector3(double x, double y, double z);
    Vector3(const Double& x, const Double& y, const Double& z);
    Vector3(const Vector3& other);
    ~Vector3() {}
    bool operator==(const Vector3& other) const
    {
        return x == other.x && y == other.y && z == other.z;
    }
    bool operator!=(const Vector3& other) const { return !(*this == other); }
    bool operator<(const Vector3& other) const
    {
        if (other == *this) return false; // This is needed bceause of precision issues
        if (x < other.x) return true;
        if (x > other.x) return false;
        if (y < other.y) return true;
        if (y > other.y) return false;
        return z < other.z;
    }

    bool isZero() const { return x.isZero() && y.isZero() && z.isZero(); }
    Vector3& operator=(const Vector3& other);
    friend Vector3 operator-(const Vector3& a) { return Vector3(-a.x, -a.y, -a.z); }
    friend Vector3 operator+(const Vector3& a, const Vector3& b);
    friend Vector3 operator-(const Vector3& a, const Vector3& b);
    friend Vector3 operator*(const Vector3& a, const Double& b);
    friend Vector3 operator/(const Vector3& a, const Double& b);
    friend Vector3 cross(const Vector3& a, const Vector3& b);
    friend Vector3 NormalizedCrossProduct(const Vector3& a, const Vector3& b);
    Double length() const
    {
        ZoneScoped;
        return sqrt(length2());
    }
    Double length2() const
    {
        ZoneScoped;
        // return x * x + y * y + z * z;
        Double s = sqr(x);
        s += sqr(y);
        s += sqr(z);
        // return sqr(x) + sqr(y) + sqr(z);
        return s;
    }
    Double invLength() const
    {
        ZoneScoped;
        return invSqrt(length2());
    }
    Vector3 normalized() const
    {
        ZoneScoped;
        // Double len = length();
        // if (len.isZero()) return Vector3(0, 0, 0);
        if (x.isZero() && y.isZero() && z.isZero()) return Vector3(0, 0, 0);
        // Double invlen = invLength();
        Double invlength = invLength();
        return Vector3(x * invlength, y * invlength, z * invlength);
    }
    friend Double dot(const Vector3 a, const Vector3& b)
    {
        Double d = a.x * b.x;
        d += a.y * b.y;
        d += a.z * b.z;
        return d;
    }
    friend bool close(const Vector3& a, const Vector3& b)
    {
        return a.x.close(b.x) && a.y.close(b.y) && a.z.close(b.z);
    }
    friend Double distance(const Vector3& a, const Vector3& b) { return (a - b).length(); }
    friend Double distance2(const Vector3& a, const Vector3& b) { return (a - b).length2(); }
    friend Double GetDistanceAlongEarth(const Vector3& a, const Vector3& b);
    friend std::ostream& operator<<(std::ostream& os, const Vector3& v);
    std::string ToString() const;

    LatLng ToLatLng() const;
    Double x, y, z;
};

class LatLng
{
public:
    Double latitude, longitude;
    LatLng() {}
    LatLng(const Double& latitude, const Double& longitude)
        : latitude(latitude)
        , longitude(longitude)
    {
    }
    ~LatLng() {}

    bool operator==(const LatLng& other) const
    {
        return latitude == other.latitude && longitude == other.longitude;
    }
    bool operator!=(const LatLng& other) const { return !(*this == other); }

    bool isZero() const { return latitude.isZero() && longitude.isZero(); }
    bool close(const LatLng& other) const
    {
        return latitude.close(other.latitude) && longitude.close(other.longitude);
    }
    Double longitudeInRad() const { return longitude * Constants::pi() / Double("180"); }
    Double latitudeInRad() const { return latitude * Constants::pi() / Double("180"); }

    Vector3 ToVector3() const;
    friend std::ostream& operator<<(std::ostream& os, const LatLng& l);
    std::string ToString() const;
};
