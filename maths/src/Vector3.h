#pragma once
#include "Constants.h"
#include "Double.h"

class LatLng;
class Vector3
{
public:
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
    friend Vector3 cross(const Vector3& a, const Vector3& b)
    {
        return Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
    }
    friend Vector3 NormalizedCrossProduct(const Vector3& a, const Vector3& b);
    Double length() const { return sqrt(x * x + y * y + z * z); }
    Double length2() const { return x * x + y * y + z * z; }
    Vector3 normalized() const
    {
        // todo: compare with zero vector?
        Double len = length2();
        if (len.isZero()) return Vector3(0, 0, 0);
        return Vector3(x / len, y / len, z / len);
    }
    friend Double dot(const Vector3 a, const Vector3& b)
    {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    friend bool close(const Vector3& a, const Vector3& b)
    {
        return a.x.close(b.x) && a.y.close(b.y) && a.z.close(b.z);
    }
    friend Double distance(const Vector3& a, const Vector3& b) { return (a - b).length(); }
    friend Double distance2(const Vector3& a, const Vector3& b) { return (a - b).length2(); }
    friend Double GetDistanceAlongSphere(const Vector3& a, const Vector3& b);
    friend std::ostream& operator<<(std::ostream& os, const Vector3& v);

    LatLng ToLatLng() const;
    Double x, y, z;
};

class LatLng
{
public:
    Double latitude, longitude;
    LatLng(const Double& latitude, const Double& longitude)
        : latitude(latitude)
        , longitude(longitude)
    {
    }

    bool isZero() const { return latitude.isZero() && longitude.isZero(); }
    bool close(const LatLng& other) const
    {
        return latitude.close(other.latitude) && longitude.close(other.longitude);
    }
    Double longitudeInRad() const { return longitude * Constants::pi() / Double(180); }
    Double latitudeInRad() const { return latitude * Constants::pi() / Double(180); }

    Vector3 ToVector3() const;
    friend std::ostream& operator<<(std::ostream& os, const LatLng& l);
};
