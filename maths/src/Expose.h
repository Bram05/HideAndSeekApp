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

    struct SegmentDart
    {
        struct LatLngDart* vertices;
        int verticesCount;
    };

    struct ShapeDart
    {
        struct SegmentDart* segments;
        int segmentsCount;
    };

    EXPOSE const void* GetSegments(const void* shape, int* length);
    EXPOSE const struct LatLngDart* GetAllVertices(const void* segments, int segmentIndex, int* length);
    EXPOSE void FreeVertices(struct LatLngDart* vertices);

    EXPOSE void* ConvertToShape(const struct ShapeDart* shapeDart);
    EXPOSE void AddFirstSide(void* shape, struct LatLngDart begin);
    EXPOSE void AddStraightSide(void* shape);
    EXPOSE void ModifyLastVertex(void* shape, struct LatLngDart point);
    EXPOSE void CloseShape(void* shape);
    EXPOSE void NewSegment(void* shape);
    EXPOSE void RemoveLastVertexAndSide(void* shape);
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

    EXPOSE void* UpdateBoundaryWithClosestToObject(void* boundary, struct LatLngDart position,
                                                   struct LatLngDart object, int closerToObject);
    EXPOSE void* UpdateBoundaryWithClosests(void* boundary, struct LatLngDart position, struct LatLngDart* objects, int numObjects, int answer);
    EXPOSE void Reverse(void* shape);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // EXPOSE_H
