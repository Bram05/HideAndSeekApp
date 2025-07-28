#include "Shape.h"
#include "Line.h"
#include "Matrix3.h"
#include <algorithm>
#include <cassert>
#include <chrono>
#include <ctime>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <stdexcept>

Side::Side(const Vector3& begin, const Vector3 between, const Vector3& end)
    : plane{ Plane::FromThreePoints(begin, between, end) }
    , begin{ begin }
    , end{ end }
{
    Vector3 directionOfFirst = cross(begin - between, plane.GetNormal());
    Line first               = Line(directionOfFirst, (begin + between) / 2);

    Vector3 directionOfSecond = cross(between - end, plane.GetNormal());
    Line second               = Line(directionOfSecond, (end + between) / 2);

    properCentre = Intersect(first, second);
}
Shape Side::FullCircle(const Vector3& centre, const Double& radius, bool clockwise)
{
    auto [plane, p1, p2] = Plane::FromCircle(centre, radius, clockwise);
    std::shared_ptr<Side> side1 =
        std::make_shared<Side>(p1, p2, plane.GetPointClosestToCentre(), plane);
    std::shared_ptr<Side> side2 =
        std::make_shared<Side>(p2, p1, plane.GetPointClosestToCentre(), plane);
    return Shape({ Segment({ side1, side2 }) }, true);
}
std::shared_ptr<Side> Side::HalfCircle(const Vector3& centre, const Double& radius, bool clockwise)
{
    auto [plane, p1, p2] = Plane::FromCircle(centre, radius, clockwise);
    std::shared_ptr<Side> side =
        std::make_shared<Side>(p1, p2, plane.GetPointClosestToCentre(), plane);
    return side;
}
std::shared_ptr<Side> Side::StraightSide(const Vector3& begin, const Vector3& end)
{
    return std::make_shared<Side>(begin, (begin + end).normalized(), end);
}

bool vec3LiesBetween(const Vector3& point, const Vector3& begin, const Vector3& end,
                     const Plane& plane, const Vector3& centre)
{
    assert(plane.LiesInside(point));
    assert(plane.LiesInside(begin));
    assert(plane.LiesInside(end));
    assert(plane.LiesInside(centre));
    if (point == begin) return true;
    if (point == end) { return false; } // this is handled by the next side
    Vector3 delta1 = begin - centre;
    Vector3 delta2 = point - centre;
    Vector3 delta3 = end - centre;
    Vector3 cross1 = NormalizedCrossProduct(delta1, delta2);
    Vector3 cross2 = NormalizedCrossProduct(delta2, delta3);
    // std::cerr << "Cross1: " << cross1 << '\n';
    // std::cerr << "Cross2: " << cross2 << '\n';
    // std::cerr << "Normal: " << plane.GetNormal() << '\n';
    if (cross1 == plane.GetNormal() && cross2 == plane.GetNormal())
    {
        return true; // point is on the first side
    }
    // std::cerr << cross1 << '\n';
    // std::cerr << plane.GetNormal() << '\n';
    assert(cross1 == plane.GetNormal() || cross1 == -plane.GetNormal() || cross1.isZero());
    assert(cross2 == plane.GetNormal() || cross2 == -plane.GetNormal() || cross2.isZero());
    return false;
}

class Timer
{
    std::chrono::time_point<std::chrono::steady_clock> begin;

public:
    Timer()
        : begin(std::chrono::steady_clock::now())
    {
    }

    void elapsed(const std::string& text)
    {
        auto end    = std::chrono::steady_clock::now();
        double time = std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count();
        std::cerr << text << " took " << time << " micros\n";
        begin = std::chrono::steady_clock::now(); // reset the timer
    }
};

std::vector<IntersectionWithDistance> IntersectSides(const Side& s1, const Side& s2)
{
    const Plane plane1         = s1.plane;
    const Plane plane2         = s2.plane;
    const Vector3& begin1      = s1.begin;
    const Vector3& end1        = s1.end;
    const Vector3& begin2      = s2.begin;
    const Vector3& end2        = s2.end;
    auto [type, intersections] = IntersectOnEarth(plane1, plane2);
    // timer.elapsed("IntersectOnEarth");
    if (type == IntersectionType::parallel) { return {}; }
    else if (type == IntersectionType::coincide)
    {
        intersections = { begin1, end1 };
        // Don't intersect duplicates into the list
        if (begin2 != begin1 && begin2 != end1) intersections.push_back(begin2);
        if (end2 != begin1 && end2 != end1) intersections.push_back(end2);
    }
    std::vector<IntersectionWithDistance> result;
    for (const Vector3& intersection : intersections)
    {
        bool first  = vec3LiesBetween(intersection, begin1, end1, plane1, s1.properCentre);
        bool second = vec3LiesBetween(intersection, begin2, end2, plane2, s2.properCentre);
        if (first && second)
        {
            Double dist1 = GetDistanceAlongEarth(begin1, intersection);
            Double dist2 = GetDistanceAlongEarth(begin2, intersection);
            result.push_back({ intersection, dist1, dist2 });
        }
    }
    // timer.elapsed("The rest");
    return result;
}

bool operator<(const PositionOnShape& lhs, const PositionOnShape& rhs)
{
    if (lhs.segmentIndex != rhs.segmentIndex) return lhs.segmentIndex < rhs.segmentIndex;
    return lhs.sideIndex < rhs.sideIndex;
}
bool operator<(const PositionForTwoShapes& lhs, const PositionForTwoShapes& rhs)
{
    if (lhs.first != rhs.first) return lhs.first < rhs.first;
    return lhs.pos < rhs.pos;
}

std::pair<const Vector3&, const Vector3&> GetBeginAndEnd(const Shape& s, PositionOnShape pos)
{
    const Segment& seg = s.segments[pos.segmentIndex];
    return { seg.sides[pos.sideIndex]->begin, seg.sides[pos.sideIndex]->end };
}

void AddBeginAndEnds(std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>>& intersections,
                     const Shape& s, bool first)
{
    for (int i = 0; i < s.segments.size(); i++)
    {
        const Segment& seg = s.segments[i];
        for (int j = 0; j < seg.sides.size(); j++)
        {
            PositionOnShape pos{ i, j };
            auto [begin, end]             = GetBeginAndEnd(s, pos);
            intersections[{ first, pos }] = {
                IntersectionOnLine{ begin, 0 },
                IntersectionOnLine{ end, GetDistanceAlongEarth(begin, end) },
            };
        }
    }
}

Double GetAngle(const std::pair<Double, Double>& a)
{
    return atan2(a.second, a.first); // The negative y is beause of the coordinate system
}

bool compareLessThan(const Double& a, const Double& b, bool mayBeEqual)
{
    if (a == b) return mayBeEqual;
    return a < b;
}

bool vec2LiesBetween(const std::pair<Double, Double>& vector1,
                     const std::pair<Double, Double>& vector2,
                     const std::pair<Double, Double>& other, bool isOutward, bool isForHit)
{
    Double a1 = GetAngle(vector1);
    Double a2 = GetAngle(vector2) - a1;
    Double ao = GetAngle(other) - a1;
    return compareLessThan(0, ao, isOutward && !isForHit) &&
           compareLessThan(ao, a2, !isOutward && !isForHit);
}

bool VectorLiesBetween(const Vector3& vector1, const Vector3& vector2, const Vector3& other,
                       const Vector3& point, bool isOutward, bool isForHit)
{
    Vector3 cross = NormalizedCrossProduct(vector1, vector2);
    if (cross.isZero())
    {
        // vectors are dependant
        // if (isOutward) return false; // We want to check if it is to the left of this line and
        // this side
        Vector3 otherCross = NormalizedCrossProduct(vector1, other);
        if (otherCross == point) { return true; }
        assert(otherCross == -point || otherCross.isZero());
        return false;
    }
    Matrix3 transformation = Matrix3(vector1, vector2, cross);
    transformation         = transformation.Inverse();
    Vector3 transformed    = transformation * other;
    if (transformed.z != 0) { throw std::runtime_error("Transformed z was not close to zero"); }
    std::pair<Double, Double> otherAs2   = { transformed.x, transformed.y };
    std::pair<Double, Double> vector1As2 = { 1, 0 };
    std::pair<Double, Double> vector2As2 = { 0, 1 };
    return vec2LiesBetween(vector1As2, vector2As2, otherAs2, isOutward, isForHit);
}

std::pair<Vector3, Vector3> GetOutwardVectors(const Shape& s, PositionOnShape pos, bool atStart,
                                              const Vector3& centre)
{
    const Segment& seg    = s.segments[pos.segmentIndex];
    const Vector3 outward = seg.sides[pos.sideIndex]->getTangent(centre);

    int previousSide =
        (pos.sideIndex - 1 + seg.sides.size()) % seg.sides.size(); // Weird modulo in cpp
    Vector3 reverseInward = atStart ? -seg.sides[previousSide]->getTangent(centre) : -outward;

    return { outward, reverseInward };
}

bool IntersectTransversely(const Shape& s1, const Shape& s2, const IntersectionWithDistance& point,
                           int seg1Index, int side1Index, int seg2Index, int side2Index,
                           bool isForHit)
{
    auto [outward1, reverseInward1] =
        GetOutwardVectors(s1, { seg1Index, side1Index }, point.distAlong1.isZero(), point.point);
    auto [outward2, reverseInward2] =
        GetOutwardVectors(s2, { seg2Index, side2Index }, point.distAlong2.isZero(), point.point);

    // print("TRANSVERSE at point ${vec3ToLatLng(point.point)}");
    // print(
    //   vectorLiesBetween(
    //     outward1,
    //     reverseInward1,
    //     outward2,
    //     point.point,
    //     true,
    //     isForHit,
    //   ),
    // );
    // print(
    //   vectorLiesBetween(
    //     outward1,
    //     reverseInward1,
    //     reverseInward2,
    //     point.point,
    //     false,
    //     isForHit,
    //   ),
    // );
    // print(
    //   vectorLiesBetween(
    //     outward2,
    //     reverseInward2,
    //     outward1,
    //     point.point,
    //     true,
    //     isForHit,
    //   ),
    // );
    // print(
    //   vectorLiesBetween(
    //     outward2,
    //     reverseInward2,
    //     reverseInward1,
    //     point.point,
    //     false,
    //     isForHit,
    //   ),
    // );

    return (!isForHit &&
            VectorLiesBetween(outward1, reverseInward1, outward2, point.point, true, isForHit)) ||
           (!isForHit && VectorLiesBetween(outward1, reverseInward1, reverseInward2, point.point,
                                           false, isForHit)) ||
           VectorLiesBetween(outward2, reverseInward2, outward1, point.point, true, isForHit) ||
           VectorLiesBetween(outward2, reverseInward2, reverseInward1, point.point, false,
                             isForHit);
}

std::tuple<std::vector<IntersectionWithIndex>,
           std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>>>
    IntersectionPoints(const Shape& s1, const Shape& s2, bool isForHit, bool checkTransverse)
{
    std::vector<IntersectionWithIndex> intersections                                     = {};
    std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>> intersectionsPerSide = {};
    AddBeginAndEnds(intersectionsPerSide, s1, true);
    AddBeginAndEnds(intersectionsPerSide, s2, false);
    for (int seg1Index = 0; seg1Index < s1.segments.size(); seg1Index++)
    {
        Segment segment1 = s1.segments[seg1Index];
        for (int side1Index = 0; side1Index < s1.segments[seg1Index].sides.size(); side1Index++)
        {
            for (int seg2Index = 0; seg2Index < s2.segments.size(); seg2Index++)
            {
                Segment segment2 = s2.segments[seg2Index];

                for (int side2Index = 0; side2Index < s2.segments[seg2Index].sides.size();
                     side2Index++)
                {
                    auto [begin1, end1] = GetBeginAndEnd(s1, { seg1Index, side1Index });
                    auto [begin2, end2] = GetBeginAndEnd(s2, { seg2Index, side2Index });

                    std::vector<IntersectionWithDistance> currentIntersections =
                        IntersectSides(*s1.segments[seg1Index].sides[side1Index],
                                       *s2.segments[seg2Index].sides[side2Index]);
                    for (const IntersectionWithDistance& point : currentIntersections)
                    {
                        if (point.distAlong1.isZero() || point.distAlong2.isZero())
                        {
                            if (checkTransverse &&
                                !IntersectTransversely(s1, s2, point, seg1Index, side1Index,
                                                       seg2Index, side2Index, isForHit))
                            {
                                // std::cerr
                                //     << "The curves do not intersect transversely at $point  from
                                //     "
                                //        "segments 1index: $side1Index and 2index: $side2Index -> "
                                //        "ignoring\n";
                                continue;
                            }
                        }
                        if (!point.distAlong1.isZero())
                            intersectionsPerSide[PositionForTwoShapes{ true, seg1Index,
                                                                       side1Index }]
                                .push_back(IntersectionOnLine{ point.point, point.distAlong1 });
                        if (!point.distAlong2.isZero())
                            intersectionsPerSide[PositionForTwoShapes{ false, seg2Index,
                                                                       side2Index }]
                                .push_back(IntersectionOnLine{ point.point, point.distAlong2 });
                        intersections.push_back(IntersectionWithIndex{
                            point.point, { seg1Index, side1Index }, { seg2Index, side2Index } });
                    }
                }
            }
        }
    }
    for (auto& [_, list] : intersectionsPerSide)
    {
        // Sort the intersections for each side by distance along the line
        std::sort(list.begin(), list.end(),
                  [](const IntersectionOnLine& a, const IntersectionOnLine& b)
                  { return a.distanceAlong < b.distanceAlong; });
    }
    // intersectionsPerSide.forEach(
    //     (k, list) = > list.sort((a, b) = > a.distanceAlong.compareTo(b.distanceAlong)), );

    return { intersections, intersectionsPerSide };
}

struct CurrentPoint
{
    Vector3 point;
    PositionForTwoShapes pos;
};

int LastIndexWhere(const std::vector<IntersectionOnLine>& intersections, const Vector3& point)
{
    for (int i = intersections.size() - 1; i >= 0; --i)
    {
        if (point == intersections[i].point) { return i; }
    }
    throw std::runtime_error("Point not found in intersections");
}

void SetNextPoint(
    std::map<PositionForTwoShapes, std::vector<IntersectionOnLine>>& intersectionsPerLine,
    CurrentPoint& currentPoint, const Shape& s1, const Shape& s2)
{
    std::vector<IntersectionOnLine> currentLine = intersectionsPerLine[currentPoint.pos];
    // When the two shapes share a side the currentLine can contain that point twice (once from the
    // current shape and a second time as 'intersection' with the other shape). We therefore choose
    // the last index where it occurs so we can actually move on instead of getting into an infinite
    // loop
    int index = LastIndexWhere(currentLine, currentPoint.point);
    Segment segment =
        (currentPoint.pos.first ? s1 : s2).segments[currentPoint.pos.pos.segmentIndex];

    if (index == currentLine.size() - 1)
    {
        currentPoint.pos.pos = { currentPoint.pos.pos.segmentIndex,
                                 (int)((currentPoint.pos.pos.sideIndex + 1) %
                                       segment.sides.size()) };
        currentPoint.point   = segment.sides[currentPoint.pos.pos.sideIndex]->begin;
    }
    else if (index == currentLine.size() - 2)
    {
        currentPoint.pos.pos = { currentPoint.pos.pos.segmentIndex,
                                 (int)((currentPoint.pos.pos.sideIndex + 1) %
                                       segment.sides.size()) };
        currentPoint.point   = segment.sides[currentPoint.pos.pos.sideIndex]->begin;
    }
    else { currentPoint.point = currentLine[index + 1].point; }
}

Shape Intersect(const Shape& s1, const Shape& s2, bool firstIsForHit)
{
    auto [intersections, intersectionsPerLine] = IntersectionPoints(s1, s2, firstIsForHit);
    for (auto in : intersections)
    {
        auto& side1 = s1.segments[in.indexInS1.segmentIndex].sides[in.indexInS1.sideIndex];
        assert(side1->plane.LiesInside(side1->begin));
        assert(side1->plane.LiesInside(side1->end));
        auto& side2 = s2.segments[in.indexInS2.segmentIndex].sides[in.indexInS2.sideIndex];
        assert(side2->plane.LiesInside(side2->begin));
        assert(side2->plane.LiesInside(side2->end));
    }
    std::map<Vector3, std::pair<PositionOnShape, PositionOnShape>> intersectionsTotal = {};
    std::set<Vector3> intersectionsLeft                                               = {};
    int count                                                                         = 0;
    std::vector<bool> segmentsIntersected1 = std::vector<bool>(s1.segments.size(), false);
    std::vector<bool> segmentsIntersected2 = std::vector<bool>(s2.segments.size(), false);
    for (const IntersectionWithIndex& data : intersections)
    {
        intersectionsTotal[data.point] = { data.indexInS1, data.indexInS2 };
        intersectionsLeft.insert(data.point);
        segmentsIntersected1[data.indexInS1.segmentIndex] = true;
        segmentsIntersected2[data.indexInS2.segmentIndex] = true;
    }
    Shape result = Shape(std::vector<Segment>{});
    for (int i = 0; i < segmentsIntersected1.size(); i++)
    {
        if (!segmentsIntersected1[i])
        {
            // printf("Segment $i in shape 1 has no intersections");
            if (s1.segments[i].sides.empty())
            {
                printf("WARNING: empty segment!!!");
                continue;
            }
            if (s2.Hit(s1.segments[i].sides.front()->begin))
            {
                result.segments.push_back(s1.segments[i]);
            }
        }
    }
    for (int i = 0; i < segmentsIntersected2.size(); i++)
    {
        if (!segmentsIntersected2[i])
        {
            // printf("Segment $i in shape 2 has no intersections");
            if (s2.segments[i].sides.empty())
            {
                printf("WARNING: empty segment!!!");
                continue;
            }
            if (s1.Hit(s2.segments[i].sides.front()->begin))
            {
                result.segments.push_back(s2.segments[i]);
            }
        }
    }
    while (!intersectionsLeft.empty())
    {
        Vector3 startPoint        = *intersectionsLeft.begin();
        CurrentPoint currentPoint = { startPoint, false, { -1, -1 } };

        Segment newSegment = Segment();
        do {
            LatLng l = currentPoint.point.ToLatLng();
            ++count;
            if (count > 1000)
            {
                std::cerr << "WARNING: Stopping due to too many loops\n";
                result.segments.push_back(newSegment);
                return result;
            }
            // std::cerr << "New run\n";
            // state.points.add(vec3ToLatLng(currentPoint.point));
            if (intersectionsTotal.find(currentPoint.point) != intersectionsTotal.end())
            {
                intersectionsLeft.erase(currentPoint.point);
                auto indices = intersectionsTotal[currentPoint.point];
                // auto vertices1     = s1.segments[indices.first.segmentIndex].vertices;
                auto sides1 = s1.segments[indices.first.segmentIndex].sides;
                // auto vertices2     = s2.segments[indices.second.segmentIndex].vertices;
                auto sides2 = s2.segments[indices.second.segmentIndex].sides;
                // Vector3 endAlongS1 = vertices1[(indices.first.sideIndex + 1) % vertices1.size()];
                // Vector3 endAlongS2 = vertices2[(indices.second.sideIndex + 1) %
                // vertices2.size()];
                Vector3 endAlongS1 = sides1[indices.first.sideIndex]->end;
                Vector3 endAlongS2 = sides2[indices.second.sideIndex]->end;

                // vertices does not contain the intersections so use currentpoint and not vertices
                Vector3 tangentAlongS1 =
                    sides1[indices.first.sideIndex]->getTangent(currentPoint.point);
                Vector3 tangentAlongS2 =
                    sides2[indices.second.sideIndex]->getTangent(currentPoint.point);
                Vector3 cross = NormalizedCrossProduct(tangentAlongS1, tangentAlongS2);
                if (cross != currentPoint.point.normalized())
                {
                    // std::cerr << "Going along shape 1\n";
                    // std::shared_ptr<Side> newside =
                    //     std::make_shared<Side>(*s1.segments[indices.first.segmentIndex]
                    //                                 .sides[currentPoint.pos.pos.sideIndex]);
                    Vector3 begin          = currentPoint.point;
                    currentPoint.pos.first = true;
                    currentPoint.pos.pos = { indices.first.segmentIndex, indices.first.sideIndex };
                    std::shared_ptr<Side> newside =
                        std::make_shared<Side>(*s1.segments[currentPoint.pos.pos.segmentIndex]
                                                    .sides[currentPoint.pos.pos.sideIndex]);
                    SetNextPoint(intersectionsPerLine, currentPoint, s1, s2);
                    newside->begin = begin;
                    newside->end   = currentPoint.point;
                    newSegment.sides.push_back(newside);
                    assert(newside->plane.LiesInside(newside->begin));
                    assert(newside->plane.LiesInside(newside->end));
                }
                else
                {
                    // std::cerr << "Going along shape 2\n";
                    Vector3 begin          = currentPoint.point;
                    currentPoint.pos.first = false;
                    currentPoint.pos.pos   = { indices.second.segmentIndex,
                                               indices.second.sideIndex };
                    std::shared_ptr<Side> newside =
                        std::make_shared<Side>(*s2.segments[currentPoint.pos.pos.segmentIndex]
                                                    .sides[currentPoint.pos.pos.sideIndex]);
                    SetNextPoint(intersectionsPerLine, currentPoint, s1, s2);
                    newside->begin = begin;
                    newside->end   = currentPoint.point;
                    assert(newside->plane.LiesInside(newside->begin));
                    assert(newside->plane.LiesInside(newside->end));
                    newSegment.sides.push_back(newside);
                }
            }
            else
            {
                // we must update the begin and end here because these may differe from the original
                // because of new intersections
                // std::shared_ptr<Side> newside =
                //     std::make_shared<Side>(*s2.segments[currentPoint.pos.pos.segmentIndex]
                //                                 .sides[currentPoint.pos.pos.sideIndex]);
                // newside->begin = currentPoint.point;
                Vector3 begin = currentPoint.point;

                Segment segment =
                    (currentPoint.pos.first ? s1 : s2).segments[currentPoint.pos.pos.segmentIndex];
                std::shared_ptr<Side> newside =
                    std::make_shared<Side>(*segment.sides[currentPoint.pos.pos.sideIndex]);
                SetNextPoint(intersectionsPerLine, currentPoint, s1, s2);
                newside->begin = begin;
                newside->end   = currentPoint.point;
                newSegment.sides.push_back(newside);
                assert(newside->plane.LiesInside(newside->begin));
                assert(segment.sides[currentPoint.pos.pos.sideIndex]->plane.LiesInside(
                    currentPoint.point));
                assert(newside->plane.LiesInside(newside->end));
            }
        } while (currentPoint.point != startPoint);
        // std::cerr << "Length: " << newSegment.sides.size() << '\n';
        // for (int i = 0; i <= newSegment.sides.size(); i++)
        // {
        //     if (newSegment.sides[i % newSegment.sides.size()]->end !=
        //         newSegment.sides[(i + 1) % newSegment.sides.size()]->begin)
        //     {
        //         std::cerr << "EROROROROR\n";
        //     }
        // }
        result.segments.push_back(newSegment);
    }

    return result;
}

Vector3 GetTangentAtIntersection(const Shape& s, PositionOnShape index, const Vector3& point)
{
    const Segment& segment = s.segments[index.segmentIndex];
    return segment.sides[index.sideIndex]->getTangent(point);
}

enum class OrientationResult
{
    positive,
    negative,
    undeterminated
};

OrientationResult areOrientedPositively(Vector3 a, Vector3 b, Vector3 point)
{
    Vector3 cross = NormalizedCrossProduct(a, b);
    if (cross.isZero()) return OrientationResult::undeterminated;
    return cross == point.normalized() ? OrientationResult::positive : OrientationResult::negative;
}

bool Shape::Hit(const Vector3& point) const
{
    Vector3 begin = point;
    LatLng l      = begin.ToLatLng();
    Vector3 end   = LatLng(l.latitude, l.longitude - 180).ToVector3();
    // todo: this does not work if latitude == 0 or 90
    // // loop around half the circle. We assume that this is enough and no curve will loop around
    // more than half the earth todo: add a check and explicitly fail otherwise todo: make sure that
    // the intersections also work when looping around the earth
    int count = 0;
    Shape s   = Shape({
        Segment({ Side::StraightSide(begin, end) }),
    });

    auto [points, _] = IntersectionPoints(s, *this, true);
    if (points.size() == 0 && surroundsPlanet)
    {
        // std::cerr << "Hit found no intersection with surrounding planet\n";
        assert(segments.size() == 1);
        assert(segments[0].sides.size() == 2 &&
               segments[0].sides[0]->plane == segments[0].sides[1]->plane);
        return dot(segments[0].sides[0]->plane.GetNormal(), point) >= 0;
    }
    for (IntersectionWithIndex p : points)
    {
        Vector3 t1 = GetTangentAtIntersection(s, p.indexInS1, p.point);
        Vector3 t2 = GetTangentAtIntersection(*this, p.indexInS2, p.point);

        switch (areOrientedPositively(t1, t2, p.point))
        {
        case OrientationResult::positive: ++count; break;
        case OrientationResult::negative: --count; break;
        case OrientationResult::undeterminated:
            break;
            // do nothing
            // We ignore it: think about turning the ray an infinitesimal amount making sure it does
            // not intersect this line anymore. The other lines are still intersected the same way
            // though
        }
    }
    return count != 0;
}
template <>
std::ostream& operator<< <Vector3>(std::ostream& os, const std::vector<Vector3>& p)
{
    os << "vector[";
    for (const Vector3& t : p) { os << t.ToLatLng() << ", "; }
    os << "]";
    return os;
}
std::ostream& operator<<(std::ostream& os, const IntersectionWithDistance& i)
{
    os << i.point.ToLatLng() << " with dist1: " << i.distAlong1 << " and dist2: " << i.distAlong2;
    return os;
}
std::ostream& operator<<(std::ostream& os, const IntersectionWithIndex& i)
{
    os << i.point.ToLatLng();
    return os;
}
void Segment::Reverse()
{
    for (auto& s : sides) { s->Reverse(); }
    std::reverse(sides.begin(), sides.end());
}
void Shape::Reverse()
{
    for (auto& s : segments) s.Reverse();
}
