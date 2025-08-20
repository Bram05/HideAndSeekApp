#pragma once
#include "Constants.h"
#include "Double.h"
#include <tracy/Tracy.hpp>

struct Vector3double;
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
        // if (other == *this)
        //     return false; // This is needed bceause of precision issues, not sure actually?
        // if (x == other.x)
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
    // a x b
    friend Vector3 cross(const Vector3& a, const Vector3& b);

    // Cross product of a and b and normalize it
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
        if (x.isZero() && y.isZero() && z.isZero()) return Vector3(0, 0, 0);
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

    // Get the distance between two points on the earth
    friend Double GetDistanceAlongEarth(const Vector3& a, const Vector3& b);

    // If the distance along earth is only needed for ordering points, then this is more efficient,
    // because it does not calculate the actual distance Be careful: if distance is 0 then this
    // returns -1
    friend Double GetDistanceAlongEarthForOrder(const Vector3& a, const Vector3& b);

    // Get the distance but less precise
    friend double GetDistanceAlongEarthImprecise(const Vector3double& a, const Vector3double& b);
    friend std::ostream& operator<<(std::ostream& os, const Vector3& v);
    std::string ToString() const;

    // Convert this vector3 to latitude and longitude coordinates
    // See the readme for information on the coordinate system used
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

    // Convert this latlng to a coordinate in three dimensional space on the unit sphere
    // See the readme for information on the coordinate system used
    Vector3 ToVector3() const;
    friend std::ostream& operator<<(std::ostream& os, const LatLng& l);
    std::string ToString() const;
};
// Vector3 but with lower precision
struct Vector3double
{
    double x, y, z;
    Vector3double(const Vector3& v)
        : x{ v.x.ToDouble() }
        , y{ v.y.ToDouble() }
        , z{ v.z.ToDouble() }
    {
    }
    Vector3double(double x, double y, double z)
        : x{ x }
        , y{ y }
        , z{ z }
    {
    }

    Vector3double operator+(Vector3double other);
    LatLngdouble ToLatLngImprecise() const;
};
