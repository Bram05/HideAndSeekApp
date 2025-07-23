#pragma once

#include "Plane.h"
#include "Vector3.h"
#include <algorithm>
#include <iostream>
#include <map>
#include <memory>
#include <ostream>
#include <stdexcept>
#include <vector>

inline bool globalPrintDebugInfo = false;

enum class SideType
{
    straight = 1, // These must match the values in Expose.h
    circle   = 0
};
class Side
{
public:
    SideType sideType;

    // todo: begin and end?
    Side(SideType type)
        : sideType(type)
    {
    }

    virtual void extendPath() = 0; // Placeholder for path extension logic

    friend bool operator==(const Side& first, const Side& other)
    {
        return first.equalsImpl(other) && first.sideType == other.sideType;
    }
    bool operator!=(const Side& other) const { return !(*this == other); }
    virtual bool equalsImpl(const Side& other) const { return true; }

    virtual ~Side()                                                        = default;
    virtual Vector3 GetProperCentre() const                                = 0;
    virtual Plane GetPlane(const Vector3& begin, const Vector3& end) const = 0;
    Vector3 getTangent(const Vector3& begin, const Vector3& end, const Vector3& point) const
    {
        Plane p               = GetPlane(begin, end);
        const Vector3& centre = GetProperCentre();
        const Vector3& cross  = Vector3(0, 0, 0);
        return NormalizedCrossProduct((centre - point), p.GetNormal());
    }
    friend std::ostream& operator<<(std::ostream& os, const Side& side)
    {
        os << "Side(type: " << static_cast<int>(side.sideType) << ")\n";
        return os;
    }
};

class StraightSide : public Side
{
public:
    StraightSide()
        : Side(SideType::straight)
    {
    }

    virtual Plane GetPlane(const Vector3& begin, const Vector3& end) const override
    {
        return Plane::FromTwoPointsAndOrigin(begin, end);
    }

    void extendPath() override
    {
        throw std::runtime_error("StraightSide does not support path extension yet.");
    }

    Vector3 GetProperCentre() const override { return Vector3(0, 0, 0); }
};

class CircleSide : public Side
{
public:
    CircleSide(const Vector3& centre, Double radius, Double startAngle, Double sweepAngle,
               const Plane& plane, bool clockwise)
        : Side(SideType::circle)
        , center(centre)
        , radius(radius)
        , startAngle(startAngle)
        , sweepAngle(sweepAngle)
        , plane{ plane }
        , properCentre{ plane.GetPointClosestToCentre() }
        , clockwise{ clockwise }
    {
    }

    virtual bool equalsImpl(const Side& other) const override
    {
        std::cerr << "Comparing circles\n";
        if (other.sideType != SideType::circle) return false;
        const CircleSide& otherCircle = static_cast<const CircleSide&>(other);
        return center == otherCircle.center && radius == otherCircle.radius &&
               startAngle == otherCircle.startAngle && sweepAngle == otherCircle.sweepAngle &&
               plane == otherCircle.plane;
    }

    virtual Plane GetPlane(const Vector3& begin, const Vector3& end) const override
    {
        return plane;
    }

    void extendPath() override
    {
        throw std::runtime_error("CircleSide does not support path extension yet.");
    }

    virtual Vector3 GetProperCentre() const override { return properCentre; }

    Vector3 center;
    Vector3 properCentre;
    Double radius, startAngle, sweepAngle; // radius in metres
    Plane plane;
    bool clockwise;
};

class Segment
{
public:
    std::vector<Vector3> vertices;
    std::vector<std::shared_ptr<Side>> sides;

    Segment() = default;
    Segment(const std::vector<Vector3>& points, const std::vector<std::shared_ptr<Side>>& sides)
        : vertices(points)
        , sides(sides)
    {
    }
    bool operator==(const Segment& other) const
    {
        if (other.vertices.size() != vertices.size() || other.sides.size() != sides.size())
        {
            if (globalPrintDebugInfo)
                std::cerr << "Size mismatch: "
                          << "this.vertices.size() = " << vertices.size()
                          << ", other.vertices.size() = " << other.vertices.size()
                          << ", this.sides.size() = " << sides.size()
                          << ", other.sides.size() = " << other.sides.size() << '\n';

            return false;
        }
        int offset = -1;
        if (vertices.size() == 0) return true;
        for (size_t i = 0; i < vertices.size(); ++i)
        {
            if (vertices[0] == other.vertices[i])
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
        for (size_t i = 0; i < vertices.size(); ++i)
        {
            if (vertices[i] != other.vertices[(i + offset) % other.vertices.size()])
            {
                std::cerr << "Vertex mismatch at index " << i << ": this = " << vertices[i]
                          << ", other = " << other.vertices[(i + offset) % other.vertices.size()]
                          << '\n';
                return false;
            }
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
};

class Shape
{
public:
    std::vector<Segment> segments;
    Shape()                     = default;
    mutable bool printDebugInfo = true;
    Shape(const std::vector<Segment>& segments)
        : segments(segments)
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
                if (segments[i] == other.segments[j] && !checked[j])
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
                              << ": this = " << segments[i].vertices[0] << ", other = not found\n";
            }
        }
        if (c > 0)
        {
            if (printDebugInfo) std::cerr << "Segments mismatches: " << c << '\n';
            return false;
        }
        if (printDebugInfo) std::cerr << "All segments match.\n";
        return true;
    }

    bool operator!=(const Shape& other) const { return !(*this == other); }

    bool Hit(const Vector3& point) const;
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
std::vector<IntersectionWithDistance> IntersectSides(const Side& s1, const Side& s2,
                                                     const Vector3& begin1, const Vector3& end1,
                                                     const Vector3& begin2, const Vector3& end2);
Shape Intersect(const Shape& a, const Shape& b, bool firstIsForHit = false);
std::tuple<std::vector<IntersectionWithIndex>,
           std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>>>
    IntersectionPoints(const Shape& s1, const Shape& s2, bool isForHit = false,
                       bool checkTransverse = true);
