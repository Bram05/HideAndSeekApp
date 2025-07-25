#include "Expose.h"
#include "Constants.h"
#include "Matrix3.h"
#include "Plane.h"
#include "Shape.h"
#include <iostream>
#include <stdexcept>
#include <utility>

const void* GetSegments(const void* shape, int* length)
{
    const Shape* shapePtr = (Shape*)shape;
    *length               = shapePtr->segments.size();
    return shapePtr->segments.data();
}

const LatLngDart* GetVertices(const void* segment, int index, int* length)
{
    const Segment* segmentPtr = &((Segment*)segment)[index];
    *length                   = segmentPtr->vertices.size();
    LatLngDart* vertices      = new LatLngDart[*length];
    for (size_t i = 0; i < segmentPtr->vertices.size(); ++i)
    {
        LatLng vertex   = segmentPtr->vertices[i].ToLatLng();
        vertices[i].lat = vertex.latitude.ToDouble();
        vertices[i].lon = vertex.longitude.ToDouble();
    }
    return vertices;
}

void FreeVertices(LatLngDart* vertices) { delete[] vertices; }

const SideDart* GetSides(const void* segmentOrig, int index, int* length)
{
    const Segment& segment = ((Segment*)segmentOrig)[index];
    *length                = segment.sides.size();
    SideDart* sides        = new SideDart[*length];
    for (size_t i = 0; i < segment.sides.size(); ++i)
    {
        sides[i].isStraight = static_cast<int>(segment.sides[i]->sideType);
        if (sides[i].isStraight != 1)
        {
            const std::shared_ptr<CircleSide>& circleSide =
                std::dynamic_pointer_cast<CircleSide>(segment.sides[i]);
            sides[i].radius           = circleSide->radius.ToDouble();
            LatLng centre             = circleSide->center.ToLatLng();
            sides[i].centre.lat       = centre.latitude.ToDouble();
            sides[i].centre.lon       = centre.longitude.ToDouble();
            LatLng properCentre       = circleSide->properCentre.ToLatLng();
            sides[i].properCentre.lat = properCentre.latitude.ToDouble();
            sides[i].properCentre.lon = properCentre.latitude.ToDouble();
            sides[i].isClockwise      = circleSide->clockwise;
            // sides[i].plane = { circleSide->plane.a.ToDouble(), circleSide->plane.b.ToDouble(),
            //                    circleSide->plane.c.ToDouble(), circleSide->plane.d.ToDouble() };
        }
    }
    return sides;
}

void FreeSides(SideDart* sides) { delete[] sides; }

std::shared_ptr<Side> CreateSide(SideDart side)
{
    std::shared_ptr<Side> res;
    if (side.isStraight) { res = std::make_shared<StraightSide>(); }
    else
    {
        LatLngDart centreDart = side.centre;
        Vector3 centre        = LatLng(centreDart.lat, centreDart.lon).ToVector3();
        res                   = std::make_shared<CircleSide>(centre, side.radius, side.isClockwise);
    }
    return res;
}

void* ConvertToShape(const ShapeDart* shape)
{
    std::vector<Segment> segments;
    for (int i = 0; i < shape->segmentsCount; ++i)
    {
        const SegmentDart& segmentDart = shape->segments[i];
        std::vector<Vector3> vertices;
        for (int j = 0; j < segmentDart.verticesCount; ++j)
        {
            LatLng vertex = LatLng(segmentDart.vertices[j].lat, segmentDart.vertices[j].lon);
            vertices.push_back(vertex.ToVector3());
        }
        std::vector<std::shared_ptr<Side>> sides;
        for (int j = 0; j < segmentDart.sidesCount; ++j)
        {
            sides.push_back(CreateSide(segmentDart.sides[i]));
        }
        segments.emplace_back(vertices, sides);
    }
    return new Shape(segments);
}
void AddVertex(void* shapeP, struct LatLngDart pointP, struct SideDart* sideP)
{
    Shape* shape  = (Shape*)shapeP;
    Vector3 point = LatLng(pointP.lat, pointP.lon).ToVector3();
    shape->segments.back().vertices.push_back(point);
    if (sideP) shape->segments.back().sides.push_back(CreateSide(*sideP));
}
void ModifyLastVertex(void* shapeP, struct LatLngDart pointP)
{
    Shape* shape  = (Shape*)shapeP;
    Vector3 point = LatLng(pointP.lat, pointP.lon).ToVector3();
    if (shape->segments.size() > 0 && shape->segments.back().vertices.size() > 0)
        shape->segments.back().vertices.back() = point;
}
void RemoveLastVertexAndSide(void* shapeP)
{
    Shape* shape = (Shape*)shapeP;
    shape->segments.back().vertices.pop_back();
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
    Shape* shapeA = (Shape*)a;
    Shape* shapeB = (Shape*)b;
    auto result   = Intersect(*shapeA, *shapeB);
    return new Shape(result);
}

static Double precision("1e-8");
int ShapesEqual(const void* a, const void* b)
{
    const Shape* shapeA = (const Shape*)a;
    const Shape* shapeB = (const Shape*)b;
    Double prev         = Constants::Precision::GetPrecision();
    Constants::Precision::SetPrecision(precision);

    bool res = *shapeA == *shapeB;
    Constants::Precision::SetPrecision(prev);
    return res;
}

void whyUnequal(const void* a, const void* b)
{
    const Shape* shapeA    = (const Shape*)a;
    const Shape* shapeB    = (const Shape*)b;
    bool copy              = shapeA->printDebugInfo;
    shapeA->printDebugInfo = true;
    Double prev            = Constants::Precision::GetPrecision();
    Constants::Precision::SetPrecision(precision);

    bool res = *shapeA == *shapeB;
    Constants::Precision::SetPrecision(prev);
    if (!res)
    {
        std::cerr << "Shapes are equal, no reason to print why\n";
        return;
    }
    shapeA->printDebugInfo = copy;
}

LatLngDart* GetIntermediatePoints(const void* shapeP, int segIndex, int sideIndex,
                                  int numIntermediatePoints)
{
    try
    {
        const Shape* shape = (const Shape*)shapeP;
        // LatLngDart* results = new LatLngDart[numIntermediatePoints];
        // auto po             = shape->segments[0].vertices[0].ToLatLng();
        // for (int i = 0; i < numIntermediatePoints; i++)
        //     results[i] = LatLngDart{ po.latitude.ToDouble(), po.longitude.ToDouble() };
        // return results;
        if (numIntermediatePoints < 2) throw std::runtime_error("Too little intermediate points");
        const Segment& segment = shape->segments[segIndex];
        const Vector3& begin   = segment.vertices[sideIndex];
        const Vector3& end     = segment.vertices[(sideIndex + 1) % segment.vertices.size()];
        const std::shared_ptr<Side>& side = segment.sides[sideIndex];
        Vector3 beginRelative             = begin - side->GetProperCentre();
        Vector3 endRelative               = end - side->GetProperCentre();
        const Vector3& normal             = side->GetPlane(begin, end).GetNormal();
        const Vector3 cross =
            NormalizedCrossProduct(normal, beginRelative) * beginRelative.length();
        Matrix3 transformation = Matrix3(beginRelative, cross, normal);
        Matrix3 inverse        = transformation.Inverse();
        LatLngDart* result     = new LatLngDart[numIntermediatePoints];
        Vector3 endTransformed = inverse * endRelative;
        if (endTransformed.z != 0)
            std::cerr << "Z is not zero!!, endtr = " << endTransformed << " from propercentre"
                      << side->GetProperCentre() << "\n";
        Double angle = atan2(endTransformed.y, endTransformed.x);
        if (angle == -Constants::pi())
        {
            // If y is slightly negative then atan2 returns a negative value, but it should be just
            // zero
            angle = Constants::pi();
        }
        // std::cerr << "Final angle: " << angle;
        // std::cerr << "Begin: " << begin.ToLatLng() << ", end: " << end.ToLatLng() << '\n';
        // std::cerr << "centre: " << side->GetProperCentre() << '\n';
        Double delta = angle / (numIntermediatePoints - 1);
        for (int i = 0; i < numIntermediatePoints; i++)
        {
            Double t = i * delta;
            Vector3 point(cos(t), sin(t), 0);

            LatLng transformed = (transformation * point + side->GetProperCentre()).ToLatLng();
            // std::cerr << "Got intermediate point " << i << ": " << transformed << '\n';
            // std::cerr << "Intermediate point " << i << "/" << numIntermediatePoints
            //           << " is: " << transformed << ", cross = " << cross << ", by t = " << t <<
            //           '\n'
            //           << std::flush;
            result[i] =
                LatLngDart{ transformed.latitude.ToDouble(), transformed.longitude.ToDouble() };
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
void* AddCircle(LatLngDart* centreP, double radius)
{
    // Vector3 centre             = LatLng("48.864716", "2.349014").ToVector3();
    Vector3 centre = LatLng(centreP->lat, centreP->lon).ToVector3();
    std::cerr << "Have centre: " << centre.ToLatLng() << '\n';
    // Double radius              = 5000000;
    auto [p, p1, p2]           = Plane::FromCircle(centre, radius, true);
    std::shared_ptr<Side> side = std::make_shared<CircleSide>(centre, radius, p, true);
    return new Shape({ Segment({ p1, p2 }, { side, side }) });
}
