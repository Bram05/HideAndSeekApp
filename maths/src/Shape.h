#pragma once

#include "Plane.h"
#include "Vector3.h"
#include <algorithm>
#include <iostream>
#include <map>
#include <memory>
#include <ostream>
#include <stdexcept>
#include <system_error>
#include <vector>

inline bool globalPrintDebugInfo = false;

class Shape;
class Side
{
public:
    Vector3 begin, end, properCentre;
    Plane plane;

    Side(const Vector3& begin, const Vector3& end, const Vector3& properCentre, const Plane& plane)
        : begin{ begin }
        , end{ end }
        , properCentre{ properCentre }
        , plane{ plane }
    {
    }
    Side(const Vector3& begin, const Vector3 between, const Vector3& end);
    static std::shared_ptr<Side> HalfCircle(const Vector3& centre, const Double& radius,
                                            bool clockwise);
    static Shape FullCircle(const Vector3& centre, const Double& radius, bool clockwise);
    static std::shared_ptr<Side> StraightSide(const Vector3& begin, const Vector3& end);

    friend bool operator==(const Side& first, const Side& other)
    {
        return first.begin == other.begin && first.end == other.end &&
               first.properCentre == other.properCentre && first.plane == other.plane;
    }
    bool operator!=(const Side& other) const { return !(*this == other); }
    void Reverse() { std::swap(begin, end); }

    virtual ~Side() = default;
    Vector3 getTangent(const Vector3& point) const
    {
        assert(plane.LiesInside(point));
        return NormalizedCrossProduct((properCentre - point), plane.GetNormal());
    }
    friend std::ostream& operator<<(std::ostream& os, const Side& side)
    {
        os << "Side(" << side.begin << " -> " << side.end << ")\n";
        return os;
    }
};

class Segment
{
public:
    std::vector<std::shared_ptr<Side>> sides;

    Segment() = default;
    Segment(const std::vector<std::shared_ptr<Side>>& sides)
        : sides(sides)
    {
    }
    bool operator==(const Segment& other) const
    {
        if (other.sides.size() != sides.size())
        {
            if (globalPrintDebugInfo)
                std::cerr << "Size mismatch: "
                          << ", this.sides.size() = " << sides.size()
                          << ", other.sides.size() = " << other.sides.size() << '\n';

            return false;
        }
        int offset = -1;
        if (sides.size() == 0) return true;
        for (size_t i = 0; i < sides.size(); ++i)
        {
            if (*sides[0] == *other.sides[i])
            {
                offset = i;
                break;
            }
        }
        if (offset == -1)
        {
            if (globalPrintDebugInfo) std::cerr << "No matching vertex found in other segment.\n";
            return false;
        }
        for (size_t i = 0; i < sides.size(); ++i)
        {
            if (*sides[i] != *other.sides[(i + offset) % other.sides.size()])
            {
                std::cerr << "Side mismatch at index " << i << ": this = " << *sides[i]
                          << ", other = " << *other.sides[i] << '\n';
                return false;
            }
        }
        return true;
    }
    bool operator!=(const Segment& other) const { return !(*this == other); }
    void Reverse();
};

struct IntersectionWithDistance
{
    Vector3 point;
    Double distAlong1, distAlong2;
};

struct PositionOnShape
{
    int segmentIndex, sideIndex;
};
struct IntersectionWithIndex
{
    Vector3 point;
    PositionOnShape indexInS1;
    PositionOnShape indexInS2;
};
class Shape
{
public:
    std::vector<Segment> segments;
    bool surroundsPlanet;
    Shape()                     = default;
    mutable bool printDebugInfo = true;
    Shape(const std::vector<Segment>& segments, bool surroundsPlanet = false)
        : segments{ segments }
        , surroundsPlanet{ surroundsPlanet }
    {
    }

    bool operator==(const Shape& other) const
    {
        globalPrintDebugInfo = false; // it is not super useful
        if (other.segments.size() != segments.size())
        {
            if (printDebugInfo)
                std::cerr << "Size mismatch: this.segments.size() = " << segments.size()
                          << ", other.segments.size() = " << other.segments.size() << '\n';
            return false;
        }
        int c = 0;
        std::vector<bool> checked(other.segments.size(), false);
        for (size_t i = 0; i < segments.size(); ++i)
        {
            bool found = false;
            for (size_t j = 0; j < other.segments.size(); ++j)
            {
                if (!checked[j] && segments[i] == other.segments[j])
                {
                    checked[j] = true;
                    found      = true;
                    break;
                }
            }
            if (!found)
            {
                ++c;
                if (printDebugInfo)
                    std::cerr << "Segment mismatch at index " << i
                              << ": this = " << segments[i].sides[0] << ", other = not found\n";
            }
        }
        if (c > 0)
        {
            if (printDebugInfo) std::cerr << "Segments mismatches: " << c << '\n';
            return false;
        }
        // if (printDebugInfo) std::cerr << "All segments match.\n";
        return true;
    }

    bool operator!=(const Shape& other) const { return !(*this == other); }

    bool Hit(const Vector3& point) const;
    bool FirstHitOrientedPositively(const Vector3& point) const;

    void Reverse();

private:
    std::pair<std::vector<IntersectionWithIndex>, std::unique_ptr<Shape>>
        GetIntersectionsForHit(const Vector3& point) const;
};

struct PositionForTwoShapes
{
    bool first;
    PositionOnShape pos;
};
struct IntersectionOnLine
{
    Vector3 point;
    Double distanceAlong;
};

template <typename T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& p)
{
    os << "vector[";
    for (const T& t : p) { os << t << ", "; }
    os << "]";
    return os;
}
template <>
std::ostream& operator<< <Vector3>(std::ostream& os, const std::vector<Vector3>& p);
std::ostream& operator<<(std::ostream& os, const IntersectionWithDistance& i);
std::ostream& operator<<(std::ostream& os, const IntersectionWithIndex& i);
// Needed for some tests
std::vector<IntersectionWithDistance> IntersectSides(const Side& s1, const Side& s2);
Shape Intersect(const Shape& a, const Shape& b, bool firstIsForHit = false);
std::tuple<std::vector<IntersectionWithIndex>,
           std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>>>
    IntersectionPoints(const Shape& s1, const Shape& s2, bool isForHit = false,
                       bool checkTransverse = true);
bool vec3LiesBetween(const Vector3& point, const Vector3& begin, const Vector3& end,
                     const Plane& plane, const Vector3& centre);
