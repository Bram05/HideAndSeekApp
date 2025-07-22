#include "Expose.h"
#include "Shape.h"
#include <iostream>

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
        sides[i].isInfinte  = segment.sides[i]->isInfinite;
        if (sides[i].isStraight != 1)
        {
            const std::shared_ptr<CircleSide>& circleSide =
                std::dynamic_pointer_cast<CircleSide>(segment.sides[i]);
            sides[i].radius           = circleSide->radius.ToDouble();
            sides[i].startAngle       = circleSide->startAngle.ToDouble();
            sides[i].sweepAngle       = circleSide->sweepAngle.ToDouble();
            LatLng centre             = circleSide->center.ToLatLng();
            sides[i].centre.lat       = centre.latitude.ToDouble();
            sides[i].centre.lon       = centre.longitude.ToDouble();
            LatLng properCentre       = circleSide->properCentre.ToLatLng();
            sides[i].properCentre.lat = properCentre.latitude.ToDouble();
            sides[i].properCentre.lon = properCentre.latitude.ToDouble();
            sides[i].plane = { circleSide->plane.a.ToDouble(), circleSide->plane.b.ToDouble(),
                               circleSide->plane.c.ToDouble(), circleSide->plane.d.ToDouble() };
        }
    }
    return sides;
}

void FreeSides(SideDart* sides) { delete[] sides; }

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
            if (segmentDart.sides[j].isStraight)
            {
                sides.emplace_back(std::make_shared<StraightSide>(segmentDart.sides[j].isInfinte));
            }
            else
            {
                LatLngDart centreDart = segmentDart.sides[j].centre;
                Vector3 centre        = LatLng(centreDart.lat, centreDart.lon).ToVector3();
                sides.push_back(std::make_shared<CircleSide>(
                    centre, segmentDart.sides[j].radius, segmentDart.sides[j].startAngle,
                    segmentDart.sides[j].sweepAngle,
                    Plane(segmentDart.sides[j].plane.a, segmentDart.sides[j].plane.b,
                          segmentDart.sides[j].plane.c, segmentDart.sides[j].plane.d)));
            }
        }
        segments.emplace_back(vertices, sides);
    }
    return new Shape(segments);
}

void FreeShape(void* shape) { delete (Shape*)shape; }
int hit(const void* shape, const LatLngDart* point)
{
    // std::cerr << "Shape::Hit called with point: " << point->lat << ", " << point->lon << '\n';
    LatLng latLng(point->lat, point->lon);
    return ((Shape*)shape)->Hit(latLng.ToVector3());
}
void* IntersectShapes(const void* a, const void* b)
{
    // std::cerr << "Intersecting two shapes\n";
    Shape* shapeA = (Shape*)a;
    Shape* shapeB = (Shape*)b;
    auto result   = Intersect(*shapeA, *shapeB);
    return new Shape(result);
}

int ShapesEqual(const void* a, const void* b)
{
    const Shape* shapeA = (const Shape*)a;
    const Shape* shapeB = (const Shape*)b;
    return *shapeA == *shapeB;
}

void whyUnequal(const void* a, const void* b)
{
    const Shape* shapeA    = (const Shape*)a;
    const Shape* shapeB    = (const Shape*)b;
    bool copy              = shapeA->printDebugInfo;
    shapeA->printDebugInfo = true;
    if (*shapeA == *shapeB)
    {
        std::cerr << "Shapes are equal, no reason to print why\n";
        return;
    }
    shapeA->printDebugInfo = copy;
    // std::cerr << "Shapes are not equal:\n";
}
