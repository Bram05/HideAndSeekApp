#include "Expose.h"
#include "Constants.h"
#include "Matrix3.h"
#include "Plane.h"
#include "Shape.h"
#include <cmath>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <tracy/Tracy.hpp>

void InitEverything()
{
    Double::Init();
    Constants::Init();
}
void DestroyEverything()
{
    Constants::Destroy();
    Double::Destroy();
    std::cerr << "Destroying\n" << std::flush;
}
const void* GetSegments(const void* shape, int* length)
{
    const Shape* shapePtr = (Shape*)shape;
    *length               = shapePtr->segments.size();
    return shapePtr->segments.data();
}

LatLngDart* GetIntermediatePoints(const void* segment, int index, int num)
{
    ZoneScoped;
    Segment* seg = (Segment*)segment;
    Shape s      = Shape({ *seg });
    return GetIntermediatePoints(&s, 0, index, num);
}

const LatLngDart* GetAllVertices(const void* shapeP, int segmentIndex, int* length)
{
    const Shape* shape     = (Shape*)shapeP;
    const Segment* segment = &shape->segments[segmentIndex];
    *length                = segment->sides.size() * 2;
    LatLngDart* vertices   = new LatLngDart[*length];
    for (size_t i = 0; i < segment->sides.size(); ++i)
    {
        LatLng vertex         = segment->sides[i]->begin.ToLatLng();
        vertices[2 * i].lat   = vertex.latitude.ToDouble();
        vertices[2 * i].lon   = vertex.longitude.ToDouble();
        LatLngDart* intPoints = GetIntermediatePoints(shape, segmentIndex, i, 3);
        vertices[2 * i + 1]   = intPoints[1];
        FreeIntermediatePoints(intPoints);
    }
    return vertices;
}
void printValue(struct LatLngDart p)
{
    LatLng l = LatLng{ p.lat, p.lon };
    std::cerr << l << std::flush;
}

void FreeVertices(LatLngDart* vertices) { delete[] vertices; }

// const SideDart* GetSides(const void* segmentOrig, int index, int* length)
// {
//     const Segment& segment = ((Segment*)segmentOrig)[index];
//     *length                = segment.sides.size();
//     SideDart* sides        = new SideDart[*length];
//     for (size_t i = 0; i < segment.sides.size(); ++i)
//     {
//         LatLngDart* intPoints = GetIntermediatePoints(&segment, i, 3);
//         sides[i].thirdPointOn = intPoints[1];
//         FreeIntermediatePoints(intPoints);
//         // sides[i].isStraight = static_cast<int>(segment.sides[i]->sideType);
//         // if (sides[i].isStraight != 1)
//         // {
//         //     const std::shared_ptr<CircleSide>& circleSide =
//         //         std::dynamic_pointer_cast<CircleSide>(segment.sides[i]);
//         //     // sides[i].radius           = circleSide->radius.ToDouble();
//         //     // LatLng properCentre       = circleSide->properCentre.ToLatLng();
//         //     // sides[i].properCentre.lat = properCentre.latitude.ToDouble();
//         //     // sides[i].properCentre.lon = properCentre.latitude.ToDouble();
//         //     // sides[i].isClockwise      = circleSide->clockwise;
//         //     // sides[i].plane = { circleSide->plane.a.ToDouble(),
//         circleSide->plane.b.ToDouble(),
//             //     //                    circleSide->plane.c.ToDouble(),
//             circleSide->plane.d.ToDouble()
//         //     };
//         // }
//     }
//     return sides;
// }
//
// void FreeSides(SideDart* sides) { delete[] sides; }
//
// std::shared_ptr<Side> CreateSide(SideDart side)
// {
//     std::shared_ptr<Side> res;
//     if (side.isStraight) { res = std::make_shared<StraightSide>(); }
//     else
//     {
//         std::cerr << "INFO: Creating circle\n Side = " << side.isStraight << " and " <<
//         side.radius
//                   << " and " << LatLng(side.properCentre.lat, side.properCentre.lon) << '\n';
//         LatLngDart centreDart = side.centre;
//         Vector3 centre        = LatLng(centreDart.lat, centreDart.lon).ToVector3();
//         res                   = std::make_shared<CircleSide>(centre, side.radius,
//         side.isClockwise);
//     }
//     return res;
// }

void* ConvertToShape(const ShapeDart* shape, int addStraightSides)
{
    std::vector<Segment> segments;
    int count = 0;
    for (int i = 0; i < shape->segmentsCount; ++i)
    {
        const SegmentDart& segmentDart = shape->segments[i];
        count += segmentDart.verticesCount;
        // std::vector<Vector3> vertices;
        // for (int j = 0; j < segmentDart.verticesCount; ++j)
        // {
        //     LatLng vertex = LatLng(segmentDart.vertices[j].lat, segmentDart.vertices[j].lon);
        //     vertices.push_back(vertex.ToVector3());
        // }
        std::vector<std::shared_ptr<Side>> sides;
        if (!addStraightSides) assert(segmentDart.verticesCount % 2 == 0);
        int delta = (addStraightSides ? 1 : 2);
        for (int j = 0; j < segmentDart.verticesCount; j += delta)
        {
            auto convert  = [](LatLngDart p) { return LatLng(p.lat, p.lon).ToVector3(); };
            Vector3 begin = convert(segmentDart.vertices[j]);
            // Vector3 between = convert(segmentDart.vertices[j + 1]);
            Vector3 end = convert(segmentDart.vertices[(j + delta) % segmentDart.verticesCount]);
            Vector3 between;
            if (addStraightSides)
                between = (begin + end).normalized();
            else
                between = convert(segmentDart.vertices[j + 1]);
            sides.push_back(std::make_shared<Side>(begin, between, end));
            // sides.emplace_back(segmentDart.vertices[i], segmentDart.vertices[i + 1],
            //                    segmentDart.vertices[(i + 2) % segmentDart.verticesCount]);
        }
        // std::vector<std::shared_ptr<Side>> sides;
        // for (int j = 0; j < segmentDart.sidesCount; ++j)
        // {
        //     sides.push_back(CreateSide(segmentDart.sides[j]));
        // }
        segments.push_back(sides);
        // std::cerr << "Segment " << i << " consisted of " << segmentDart.verticesCount
        //           << " vertices\n";
    }
    std::cerr << "Converted new shape with " << count << " vertices\n" << std::flush;
    return new Shape(segments);
}
Double delta = "0.000001";
void AddFirstSide(void* shapeP, struct LatLngDart beginP)
{
    Shape* shape    = (Shape*)shapeP;
    Vector3 begin   = LatLng(beginP.lat, beginP.lon).ToVector3();
    Double lat      = beginP.lat + delta;
    Vector3 end     = LatLng(lat, beginP.lon).ToVector3();
    Vector3 between = (end + begin).normalized();
    if (shape->segments.size() == 0) { throw std::runtime_error("Cannot add to no segments"); }
    auto side = std::make_shared<Side>(begin, between, end);
    shape->segments.back().sides.push_back(side);
}
void AddStraightSide(void* shapeP)
{
    Shape* shape         = (Shape*)shapeP;
    const Vector3& begin = shape->segments.back().sides.back()->end;
    LatLng l             = begin.ToLatLng();
    Double lat           = l.latitude + delta;
    Vector3 end          = LatLng(lat, l.longitude).ToVector3();

    Vector3 between = (end + begin).normalized();
    if (shape->segments.size() == 0 || shape->segments.back().sides.size() == 0)
    {
        throw std::runtime_error("Cannot add to no segments or empty segment");
    }
    auto side = std::make_shared<Side>(begin, between, end);
    shape->segments.back().sides.push_back(side);
}
void ModifyLastVertex(void* shapeP, struct LatLngDart pointP)
{
    Shape* shape  = (Shape*)shapeP;
    Vector3 point = LatLng(pointP.lat, pointP.lon).ToVector3();
    if (shape->segments.size() > 0 && shape->segments.back().sides.size() > 0)
    {
        Vector3 begin = shape->segments.back().sides.back()->begin;
        shape->segments.back().sides.pop_back();
        Vector3 between = (begin + point).normalized();
        shape->segments.back().sides.push_back(std::make_shared<Side>(begin, between, point));
    }

    else
        throw std::runtime_error("Cannot modify last vertex if none exists");
}
void CloseShape(void* shapeP)
{
    Shape* shape = (Shape*)shapeP;
    if (shape->segments.size() == 0) return;
    Segment& seg           = shape->segments.back();
    const Vector3& begin   = seg.sides.back()->end;
    const Vector3& end     = seg.sides.front()->begin;
    const Vector3& between = (begin + end).normalized();
    auto side              = std::make_shared<Side>(begin, between, end);
    seg.sides.push_back(side);
}
void RemoveLastVertexAndSide(void* shapeP)
{
    Shape* shape = (Shape*)shapeP;
    shape->segments.back().sides.pop_back();
}
void NewSegment(void* shapeP)
{
    Shape* shape = (Shape*)shapeP;
    shape->segments.push_back({});
}

void FreeShape(void* shape) { delete (Shape*)shape; }
int hit(const void* shape, const LatLngDart* point)
{
    LatLng latLng(point->lat, point->lon);
    return ((Shape*)shape)->Hit(latLng.ToVector3());
}
int FirstHitOrientedPositively(const void* shape, const struct LatLngDart* point)
{
    LatLng latLng(point->lat, point->lon);
    return ((Shape*)shape)->FirstHitOrientedPositively(latLng.ToVector3());
}
void* IntersectShapes(const void* a, const void* b)
{
    ZoneScoped;
    Shape* shapeA = (Shape*)a;
    Shape* shapeB = (Shape*)b;
    auto result   = Intersect(*shapeA, *shapeB);
    return new Shape(result);
}

static Double newEpsilon("1e-5");
int ShapesEqual(const void* a, const void* b)
{
    const Shape* shapeA = (const Shape*)a;
    const Shape* shapeB = (const Shape*)b;
    Double prev         = Constants::GetEpsilon();
    Constants::SetEpsilon(newEpsilon);

    bool res = *shapeA == *shapeB;
    Constants::SetEpsilon(prev);
    return res;
}

void whyUnequal(const void* a, const void* b)
{
    const Shape* shapeA    = (const Shape*)a;
    const Shape* shapeB    = (const Shape*)b;
    bool copy              = shapeA->printDebugInfo;
    shapeA->printDebugInfo = true;
    Double prev            = Constants::GetEpsilon();
    Constants::SetEpsilon(newEpsilon);

    bool res = *shapeA == *shapeB;
    Constants::SetEpsilon(prev);
    if (res)
    {
        std::cerr << "Shapes are equal, no reason to print why\n";
        return;
    }
    shapeA->printDebugInfo = copy;
}

LatLngDart* GetIntermediatePoints(const void* shapeP, int segIndex, int sideIndex,
                                  int numIntermediatePoints)
{
    ZoneScoped;
    try
    {
        const Shape* shape = (const Shape*)shapeP;

        // LatLngDart* results = new LatLngDart[numIntermediatePoints];
        // auto po             = shape->segments[0].vertices[0].ToLatLng();
        // for (int i = 0; i < numIntermediatePoints; i++)
        //     results[i] = LatLngDart{ po.latitude.ToDouble(), po.longitude.ToDouble() };
        // return results;
        if (numIntermediatePoints < 2) throw std::runtime_error("Too little intermediate points");
        const Segment& segment            = shape->segments[segIndex];
        const Vector3& begin              = segment.sides[sideIndex]->begin;
        const Vector3& end                = segment.sides[sideIndex]->end;
        const std::shared_ptr<Side>& side = segment.sides[sideIndex];
        assert(side->plane.LiesInside(begin));
        assert(side->plane.LiesInside(end));
        // assert(side->begin == shape->segments[segIndex]
        //                           .sides[(sideIndex - 1 + shape->segments[segIndex].sides.size())
        //                           %
        //                                  shape->segments[segIndex].sides.size()]
        //                           ->end);
        // assert(side->begin == shape->segments[segIndex]
        //                           .sides[(sideIndex + 1 + shape->segments[segIndex].sides.size())
        //                           %
        //                                  shape->segments[segIndex].sides.size()]
        //                           ->end);
        Vector3 beginRelative = begin - side->properCentre;
        Vector3 endRelative   = end - side->properCentre;
        const Vector3& normal = side->plane.GetNormal();
        const Vector3 cross =
            NormalizedCrossProduct(normal, beginRelative) * beginRelative.length();
        Matrix3 transformation = Matrix3(beginRelative, cross, normal);
        // Matrix3 inverse        = transformation.Inverse();
        LatLngDart* result = new LatLngDart[numIntermediatePoints];
        // Vector3 endTransformed = inverse * endRelative;
        Vector3 endTransformed =
            Vector3(dot(beginRelative, end), dot(cross, end), 0); // dot(normal, end) = 0
        // assert(dot(normal, end) == 0);
        if (endTransformed.z != 0)
            std::cerr << "Z is not zero!!, endtr = " << endTransformed << " from propercentre"
                      << side->properCentre << "\n";
        double angle = std::atan2(endTransformed.y.ToDouble(), endTransformed.x.ToDouble());
        // Double angle = atan2(endTransformed.y, endTransformed.x);
        double epsilon = 1e-6;
        if (std::abs(epsilon - M_PI) < epsilon)
        {
            // If y is slightly negative then atan2 returns a negative value, but it should be just
            // zero
            // angle = Constants::pi();
            angle = M_PI;
        }
        // std::cerr << "Final angle: " << angle;
        // std::cerr << "Begin: " << begin.ToLatLng() << ", end: " << end.ToLatLng() << '\n';
        // std::cerr << "centre: " << side->GetProperCentre() << '\n';

        Matrix3double transformImprecise = transformation;
        double delta                     = angle / (numIntermediatePoints - 1);
        for (int i = 0; i < numIntermediatePoints; i++)
        {
            ZoneScoped;
            Double t = i * delta;
            TracyMessageL("1");
            // Vector3 point(cos(t), sin(t), 0);
            double x = std::cos(t.ToDouble());
            double y = std::sin(t.ToDouble());
            Vector3double point{ std::cos(t.ToDouble()), std::sin(t.ToDouble()), 0 };
            TracyMessageL("2");

            LatLngdouble transformed =
                (transformImprecise * point + Vector3double(side->properCentre))
                    .ToLatLngImprecise();
            TracyMessageL("3");
            // std::cerr << "Got intermediate point " << i << ": " << transformed << '\n';
            // std::cerr << "Intermediate point " << i << "/" << numIntermediatePoints
            //           << " is: " << transformed << ", cross = " << cross << ", by t = " << t <<
            //           '\n'
            //           << std::flush;
            result[i] = LatLngDart{ transformed.latitude, transformed.longitude };
            TracyMessageL("4");
        }
        return result;
    }
    catch (std::exception e)
    {
        std::cerr << "Failed to render object: " << e.what() << '\n';
        return nullptr;
    }
}

void FreeIntermediatePoints(LatLngDart* points) { delete[] points; }
int GetNumberOfSegments(const void* shape) { return ((const Shape*)shape)->segments.size(); }
int GetNumberOfSidesInSegment(const void* shape, int segmentIndex)
{
    return ((const Shape*)shape)->segments[segmentIndex].sides.size();
}
// void* AddCircle(LatLngDart* centreP, double radius)
// {
//     // Vector3 centre             = LatLng("48.864716", "2.349014").ToVector3();
//     // Vector3 centre = LatLng(centreP->lat, centreP->lon).ToVector3();
//     // std::cerr << "Have centre: " << centre.ToLatLng() << '\n';
//     // // Double radius              = 5000000;
//     // auto [p, p1, p2]           = Plane::FromCircle(centre, radius, true);
//     // std::shared_ptr<Side> side = std::make_shared<CircleSide>(centre, radius, p, true);
//     // return new Shape({ Segment({ p1, p2 }, { side, side }) });
// }
//
void* UpdateBoundaryWithClosestToObject(void* boundary, LatLngDart positionP, LatLngDart objectP,
                                        int closerToObject)
{
    Vector3 position = LatLng{ positionP.lat, positionP.lon }.ToVector3();
    Vector3 object   = LatLng{ objectP.lat, objectP.lon }.ToVector3();
    Vector3 middle   = (position + object).normalized();
    Plane p          = Plane((object - position).normalized() * (closerToObject ? 1 : -1), middle);
    std::shared_ptr<Side> firstSide  = std::make_shared<Side>(middle, -middle, Vector3(0, 0, 0), p);
    std::shared_ptr<Side> secondSide = std::make_shared<Side>(-middle, middle, Vector3(0, 0, 0), p);
    Shape shape                      = Shape({ Segment({ firstSide, secondSide }) }, true);

    return IntersectShapes(boundary, &shape);
}
void* UpdateBoundaryWithClosests(void* boundaryP, struct LatLngDart positionP,
                                 struct LatLngDart* objectsP, int numObjects, int answer)
{
    int closestIndex   = -1;
    Double minDistance = "10000000000000000000000";
    Vector3 position   = LatLng(positionP.lat, positionP.lon).ToVector3();
    std::vector<Vector3> objects(numObjects);
    for (int i = 0; i < numObjects; i++)
    {
        objects[i]  = LatLng(objectsP[i].lat, objectsP[i].lon).ToVector3();
        Double dist = GetDistanceAlongEarth(objects[i], position);
        if (dist < minDistance)
        {
            minDistance  = dist;
            closestIndex = i;
        }
    }

    Shape* boundary = (Shape*)boundaryP;
    for (int i = 0; i < numObjects; i++)
    {
        if (i == closestIndex) continue;
        void* newBoundary =
            UpdateBoundaryWithClosestToObject(boundary, objectsP[closestIndex], objectsP[i], false);
        delete boundary;
        boundary = (Shape*)newBoundary;
    }
    if (!answer) { boundary->Reverse(); }
    return boundary;
}
void Reverse(void* shape) { ((Shape*)shape)->Reverse(); }
