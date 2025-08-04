#pragma once

#include "Line.h"
#include "Vector3.h"
#include <cassert>
#include <optional>
#include <tuple>
#include <vector>

enum class IntersectionType
{
    normal,
    parallel,
    coincide
};

class Plane
{
public:
    Double a, b, c, d;

    Plane(Double a, Double b, Double c, Double d);
    ~Plane() {}

    Plane(const Vector3& normal, const Vector3& point);

    bool operator==(const Plane& other) const
    {
        return a == other.a && b == other.b && c == other.c && d == other.d;
    }
    void Reverse();
    Vector3 GetNormal() const { return Vector3(a, b, c); }
    Vector3 GetPointClosestToCentre() const;
    Vector3 GetAPointOn() const { return GetPointClosestToCentre(); }
    static Plane FromThreePoints(const Vector3& a, const Vector3& b, const Vector3& c);
    static Plane FromTwoPointsAndOrigin(const Vector3& a, const Vector3& b);
    static std::tuple<Plane, Vector3, Vector3> FromCircle(const Vector3& centre,
                                                          const Double& radius, bool clockwise);
    bool LiesInside(const Vector3& point) const;

    friend std::tuple<IntersectionType, std::optional<Line>> Intersect(const Plane& a,
                                                                       const Plane& b);
    friend std::tuple<IntersectionType, std::vector<Vector3>> IntersectOnEarth(const Plane& a,
                                                                               const Plane& b);
};

std::ostream& operator<<(std::ostream& os, const Plane& p);
