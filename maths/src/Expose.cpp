#include "Expose.h"
#include "Constants.h"
#include "Double.h"
#include "Matrix3.h"
#include "Plane.h"
#include "Shape.h"
#include "Vector3.h"
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
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
    return GetIntermediatePoints(&s, 0, index, num, nullptr, 0, 0);
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
        LatLngDart* intPoints = GetIntermediatePoints(shape, segmentIndex, i, 3, nullptr, 0, 0);
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

void* ConvertToShape(const ShapeDart* shape, int addStraightSides, int toSkip)
{
    ZoneScoped;
    // std::cerr << "COnverting to shape!!!\n";
    std::vector<Segment> segments;
    int count = 0;
    for (int i = 0; i < shape->segmentsCount; ++i)
    {
        const SegmentDart& segmentDart = shape->segments[i];
        count += segmentDart.verticesCount;
        std::vector<std::shared_ptr<Side>> sides;
        if (!addStraightSides) assert(segmentDart.verticesCount % 2 == 0);
        int delta       = (addStraightSides ? 1 : 2);
        int toSkipInner = toSkip;
        if (segmentDart.verticesCount < 200) toSkipInner = 1;
        for (int j = 0; j < segmentDart.verticesCount; j += delta * toSkipInner)
        {
            ZoneScoped;
            auto convert = [](LatLngDart p) { return LatLng(p.lat, p.lon).ToVector3(); };
            TracyMessageL("After convert");
            Vector3 begin = convert(segmentDart.vertices[j]);
            // Vector3 between = convert(segmentDart.vertices[j + 1]);
            int endindex = j + delta * toSkipInner;
            if (endindex >= segmentDart.verticesCount) endindex = 0;
            Vector3 end = convert(segmentDart.vertices[endindex]);
            Vector3 between;
            TracyMessageL("After convert2");
            if (addStraightSides && toSkipInner == 1)
                between = (begin + end).normalized();
            else
            {
                int middle =
                    j + (delta * toSkipInner) /
                            2; // In this branch: addstraightside == false or toSkipInner>1,
                               // if addstraightside == false then delta = 2
                               // Therefore delta*toskip > 1, so 1 <= (delta*toSkipInner)/2 <
                               // (delta*toSkipInner) so we are always taking a correct point
                if (middle >= segmentDart.verticesCount) { between = (begin + end).normalized(); }
                else
                    between = convert(segmentDart.vertices[middle]);
            }
            TracyMessageL("Before end");
            sides.push_back(std::make_shared<Side>(begin, between, end));
        }
        segments.push_back(sides);
    }
    return new Shape(segments);
}
const Double delta = "0.000001";
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
void* IntersectShapes(const void* a, const void* b)
{
    ZoneScoped;
    Shape* shapeA = (Shape*)a;
    Shape* shapeB = (Shape*)b;
    auto result   = Intersect(shapeA, shapeB);
    return new Shape(result);
}

static const Double newEpsilon("1e-4");
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
void* CreateCircle(LatLngDart centre, double radius)
{
    LatLng c = LatLng(centre.lat, centre.lon);
    Shape s  = Side::FullCircle(c.ToVector3(), radius, true);
    return new Shape(s);
}

LatLngDart* GetIntermediatePoints(const void* shapeP, int segIndex, int sideIndex,
                                  double meterPerIntermediatePoint, int* numPoints, int max,
                                  int min)
{
    ZoneScoped;
    try
    {
        const Shape* shape                = (const Shape*)shapeP;
        const Segment& segment            = shape->segments[segIndex];
        const Vector3& begin              = segment.sides[sideIndex]->begin;
        const Vector3& end                = segment.sides[sideIndex]->end;
        const std::shared_ptr<Side>& side = segment.sides[sideIndex];

        // LatLngDart* results = new LatLngDart[numIntermediatePoints];
        // auto po             = shape->segments[0].vertices[0].ToLatLng();
        // for (int i = 0; i < numIntermediatePoints; i++)
        //     results[i] = LatLngDart{ po.latitude.ToDouble(), po.longitude.ToDouble() };
        // return results;
        double distance = GetDistanceAlongEarthImprecise(begin, end);

        // This rounding is not perfect but it does not matter too much in most cases
        int numIntermediatePoints;
        if (numPoints != nullptr)
        {
            numIntermediatePoints =
                std::clamp((int)(distance / meterPerIntermediatePoint), min, max);
            *numPoints = numIntermediatePoints;
        }
        else { numIntermediatePoints = meterPerIntermediatePoint; }
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
        // if (endTransformed.z != 0)
        //     std::cerr << "Z is not zero!!, endtr = " << endTransformed << " from propercentre"
        //               << side->properCentre << "\n";
        double angle = std::atan2(endTransformed.y.ToDouble(), endTransformed.x.ToDouble());
        // Double angle = atan2(endTransformed.y, endTransformed.x);
        double epsilon = 1e-6;
        if (std::abs(angle + M_PI) < epsilon)
        {
            // std::cerr << "Changin angle\n";
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

void* UpdateBoundaryWithClosestToObject(void* boundary, LatLngDart positionP, LatLngDart objectP)
{
    Vector3 position                 = LatLng{ positionP.lat, positionP.lon }.ToVector3();
    Vector3 object                   = LatLng{ objectP.lat, objectP.lon }.ToVector3();
    Vector3 middle                   = (position + object).normalized();
    Plane p                          = Plane((object - position).normalized() * -1, middle);
    std::shared_ptr<Side> firstSide  = std::make_shared<Side>(middle, -middle, Vector3(0, 0, 0), p);
    std::shared_ptr<Side> secondSide = std::make_shared<Side>(-middle, middle, Vector3(0, 0, 0), p);
    Shape shape                      = Shape({ Segment({ firstSide, secondSide }) }, true);

    if (boundary)
        return IntersectShapes(boundary, &shape);
    else
        return new Shape(shape);
}
void* UpdateBoundaryWithClosests(void* boundaryP, struct LatLngDart positionP,
                                 struct LatLngDart* objectsP, int numObjects, int answer,
                                 int deleteFirst)
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

    Shape* boundary = nullptr;
    int first       = closestIndex == 0 ? 1 : 0;
    for (int i = 0; i < numObjects; i++)
    {
        if (i == closestIndex) continue;
        void* newBoundary =
            UpdateBoundaryWithClosestToObject(boundary, objectsP[closestIndex], objectsP[i]);
        if (i != first || deleteFirst) delete boundary;
        boundary = (Shape*)newBoundary;
    }
    if (!answer) { boundary->Reverse(); }
    return IntersectShapes(boundary, boundaryP);
}
void Reverse(void* shape) { ((Shape*)shape)->Reverse(); }
// void GetBounds(const void* shapeP, double* minLat, double* maxLat, double* minLon, double*
// maxLon)
// {
//     double minLati = 10000, maxLati = -10000, minLoni = 10000, maxLoni = -10000;
//     Shape* shape = (Shape*)shapeP;
//     for (const Segment& seg : shape->segments)
//     {
//         for (const std::shared_ptr<Side>& side : seg.sides)
//         {
//             LatLng lat = side->begin.ToLatLng();
//             if (lat.latitude < minLati) minLati = lat.latitude.ToDouble();
//             if (lat.latitude > maxLati) maxLati = lat.latitude.ToDouble();
//             if (lat.longitude < minLoni) minLoni = lat.longitude.ToDouble();
//             if (lat.longitude > maxLoni) maxLoni = lat.longitude.ToDouble();
//         }
//     }
//     *minLat = minLati;
//     *maxLat = maxLati;
//     *minLon = minLoni;
//     *maxLon = maxLoni;
// }
void* LatitudeQuestion(void* shapeP, double latitude, int theirsHigher)
{
    Shape* shape   = (Shape*)shapeP;
    Vector3 centre = Vector3(0, 0, theirsHigher ? 1 : -1);
    Double radius  = GetDistanceAlongEarth(centre, LatLng(latitude, 0).ToVector3());
    Shape s        = Side::FullCircle(centre, radius, true);
    Shape result   = Intersect(shape, &s);
    return new Shape(std::move(result));
}
void* LongitudeQuestion(void* shapeP, double longitude, int theirsHigher)
{
    Shape* shape   = (Shape*)shapeP;
    Vector3 centre = LatLng(0, longitude + 90 * (theirsHigher ? 1 : -1)).ToVector3();
    Double radius  = 0.25 * Constants::CircumferenceEarth();
    Shape s        = Side::FullCircle(centre, radius, true);
    Shape result   = Intersect(shape, &s);
    return new Shape(std::move(result));
}
int IsValid(void* shapeP, int* segment, int* side)
{
    Shape* shape = (Shape*)shapeP;
    for (int i = 0; i < shape->segments.size(); i++)
    {
        int l = shape->segments[i].sides.size();
        for (int j = 0; j < l; j++)
        {
            if (shape->segments[i].sides[j]->end != shape->segments[i].sides[(j + 1) % l]->begin)
            {
                *segment = i;
                *side    = j;
                return 0;
            }
        }
    }
    return 1;
}
void* AdminAreaQuesiton(void* shapeP, void* regionsP, int length, LatLngDart positionP, int same)
{
    try
    {
        Shape* shape      = (Shape*)shapeP;
        Shape** regionsPP = (Shape**)regionsP;
        Vector3 position  = LatLng(positionP.lat, positionP.lon).ToVector3();
        std::vector<Shape*> regions(length);
        for (int i = 0; i < length; i++) { regions[i] = (Shape*)regionsPP[i]; }
        int index = -1;
        for (int i = 0; i < length; i++)
        {
            if (regions[i]->Hit(position))
            {
                std::cerr << "In area " << i << '\n';
                index = i;
                break;
            }
        }
        if (index == -1)
        {
            std::cerr << "ERROR: position is not in any subarean\n";
            return nullptr;
        }
        if (same)
        {
            Shape s = Intersect(shape, regions[index]);
            return new Shape(s);
        }
        Shape* copy = regions[index];
        copy->Reverse();
        Shape s = Intersect(shape, copy);
        return new Shape(s);
    }
    catch (std::exception e)
    {
        return nullptr;
    }
}
void* WithinRadiusQuestion(void* shapeP, LatLngDart centreP, double radius, int answer)
{
    Shape* shape  = (Shape*)shapeP;
    LatLng centre = LatLng(centreP.lat, centreP.lon);
    Shape circle  = Side::FullCircle(centre.ToVector3(), radius, true);
    if (!answer) circle.Reverse();
    return IntersectShapes(shape, &circle);
}
double DistanceBetween(LatLngDart p1P, LatLngDart p2P)
{
    LatLng p1 = LatLng(p1P.lat, p1P.lon);
    LatLng p2 = LatLng(p2P.lat, p2P.lon);
    return GetDistanceAlongEarthImprecise(p1.ToVector3(), p2.ToVector3());
}
