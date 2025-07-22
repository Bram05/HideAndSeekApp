#ifndef EXPOSE_H
#define EXPOSE_H

#define EXPOSE __attribute__((visibility("default")))
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

    struct LatLngDart
    {
        double lat;
        double lon;
    };
    struct PlaneDart
    {
        double a, b, c, d;
    };

    struct SideDart
    {
        int isStraight; // 1 for straight, 0 for circle
        int isInfinte;
        struct LatLngDart centre, properCentre;
        struct PlaneDart plane;
        double radius, startAngle, sweepAngle;
    };

    struct SegmentDart
    {
        struct LatLngDart* vertices;
        int verticesCount;
        struct SideDart* sides;
        int sidesCount;
    };

    struct ShapeDart
    {
        struct SegmentDart* segments;
        int segmentsCount;
    };

    EXPOSE const void* GetSegments(const void* shape, int* length);
    EXPOSE const struct LatLngDart* GetVertices(const void* segment, int index, int* length);
    EXPOSE void FreeVertices(struct LatLngDart* vertices);
    EXPOSE const struct SideDart* GetSides(const void* segment, int index, int* length);
    EXPOSE void FreeSides(struct SideDart* sides);

    EXPOSE void* ConvertToShape(const struct ShapeDart* shapeDart);
    EXPOSE void FreeShape(void* shape);
    EXPOSE int hit(const void* shape, const struct LatLngDart* point);
    EXPOSE void* IntersectShapes(const void* a, const void* b);
    EXPOSE int ShapesEqual(const void* a, const void* b);
    EXPOSE void whyUnequal(const void* a, const void* b);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // EXPOSE_H
