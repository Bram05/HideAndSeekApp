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

    struct SideDart
    {
        int isStraight, isClockwise; // 1 for straight, 0 for circle
        struct LatLngDart centre, properCentre;
        double radius;
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
    EXPOSE const struct LatLngDart* GetVertices(const void* segments, int index, int* length);
    EXPOSE void FreeVertices(struct LatLngDart* vertices);
    EXPOSE const struct SideDart* GetSides(const void* segments, int index, int* length);
    EXPOSE void FreeSides(struct SideDart* sides);

    EXPOSE void* ConvertToShape(const struct ShapeDart* shapeDart);
    EXPOSE void FreeShape(void* shape);
    EXPOSE int hit(const void* shape, const struct LatLngDart* point);
    EXPOSE void* IntersectShapes(const void* a, const void* b);
    EXPOSE int ShapesEqual(const void* a, const void* b);
    EXPOSE void whyUnequal(const void* a, const void* b);
    EXPOSE struct LatLngDart* GetIntermediatePoints(const void* shape, int segIndex, int sideIndex,
                                                    int numIntermediatePoints);
    EXPOSE void FreeIntermediatePoints(struct LatLngDart* points);
    EXPOSE int GetNumberOfSegments(const void* shape);
    EXPOSE int GetNumberOfSidesInSegment(const void* shape, int segmentIndex);
    EXPOSE void* AddCircle(struct LatLngDart* centre, double radius);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // EXPOSE_H
