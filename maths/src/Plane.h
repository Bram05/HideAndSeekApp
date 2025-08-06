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

// ax+by+cz=d
class Plane
{
public:
    Double a, b, c, d;

    Plane(Double a, Double b, Double c, Double d);
    ~Plane() {}

    Plane(const Vector3& normal, const Vector3& point);
    // Construct a plane from three points on it, this throws if the points are collinear
    static Plane FromThreePoints(const Vector3& a, const Vector3& b, const Vector3& c);
    static Plane FromTwoPointsAndOrigin(const Vector3& a, const Vector3& b);
    // Construct the plane corresponding to the circle, i.e. the given circle on the earth is the
    // intersection of this plane with the earth itself
    // @param radius in meters
    static std::tuple<Plane, Vector3, Vector3> FromCircle(const Vector3& centre,
                                                          const Double& radius, bool clockwise);
    bool operator==(const Plane& other) const
    {
        return a == other.a && b == other.b && c == other.c && d == other.d;
    }
    // Reverse the 'inside' of the plane (i.e. reverse the normal vector)
    void Reverse();
    Vector3 GetNormal() const { return Vector3(a, b, c); }

    // Get the point on the plane that is closed to the origin (0,0,0)
    Vector3 GetPointClosestToCentre() const;
    Vector3 GetAPointOn() const { return GetPointClosestToCentre(); }

    // Does this point lie inside the plane
    bool LiesInside(const Vector3& point) const;

    friend std::tuple<IntersectionType, std::optional<Line>> Intersect(const Plane& a,
                                                                       const Plane& b);
    // Intersect the planes and find the intersections lying on the earth (radius 1 here)
    friend std::tuple<IntersectionType, std::vector<Vector3>> IntersectOnEarth(const Plane& a,
                                                                               const Plane& b);
};

std::ostream& operator<<(std::ostream& os, const Plane& p);
