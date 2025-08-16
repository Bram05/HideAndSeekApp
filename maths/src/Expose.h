#ifndef EXPOSE_H
#define EXPOSE_H

// All functions that are needed in dart
// Dart keeps a Shape* that points to the shape in cpp code
// This is then passed to every function that operates on a shape or to query information about it
// such as the number of segments or sides
#ifdef __WIN32
#error "Cannot compile for windows"
#else
#define EXPOSE __attribute__((visibility("default")))
#endif
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

    // ----section: classes to give input to cpp----
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

    // Print a latlngdart to stderr
    EXPOSE void printValue(struct LatLngDart p);

    // Convert the ShapeDart to a shape in cpp memory
    EXPOSE void* ConvertToShape(const struct ShapeDart* shapeDart, int addStraigthSides,
                                int toSkip);

    // ----section: Modifying shape -----
    // Add the first side to a new segment
    // The constructed side consists of a straight side from begin to itself (actually a point very
    // close to begin)
    EXPOSE void AddFirstSide(void* shape, struct LatLngDart begin);

    // Add a new 'empty' side (side consisting of basically the same point twice) to shape
    EXPOSE void AddStraightSide(void* shape);
    // Change the last vertex to point
    EXPOSE void ModifyLastVertex(void* shape, struct LatLngDart point);
    // Add a line from end to begin of the shape
    EXPOSE void CloseShape(void* shape);
    // Add a new empty segment
    EXPOSE void NewSegment(void* shape);
    // Remove the last side from shape
    EXPOSE void RemoveLastVertexAndSide(void* shape);

    // Create circle
    EXPOSE void* CreateCircle(struct LatLngDart centre, double radius);

    // Free all memory for shape
    EXPOSE void FreeShape(void* shape);

    // Reverse the entire shape, i.e. inside becomes ouside and vice versa
    // This is achieved by reversing the orientation of every side
    EXPOSE void Reverse(void* shape);

    // ----section: Queriying shape----
    // Rendering comes down to: GetNumberOfSegments -> for each segment GetNumberOfSides -> for each
    // side GetIntermediatePoints -> render a straight line between these
    //
    // Is point contained inside shape
    EXPOSE int hit(const void* shape, const struct LatLngDart* point);
    // Is the shape valid, i.e. 'end' of a side matches the 'begin' of the next
    EXPOSE int IsValid(void* shape, int* segment, int* side);

    // What is the intersectiong of a and b
    EXPOSE void* IntersectShapes(const void* a, const void* b);
    // Are a and b equal to each other
    // @returns 1 if true, 0 otherwise
    EXPOSE int ShapesEqual(const void* a, const void* b);
    // Print why a is unequal to b, sometimes useful for debugging
    EXPOSE void whyUnequal(const void* a, const void* b);
    // Get the segments from the shape
    // Returns: Segment*  <--- Dart cannot access this; it must be passed to
    // out parameter length: how many segments are there
    EXPOSE const void* GetSegments(const void* shape, int* length);

    // Get all vertices from a specific segment
    // @param shape: the shape
    // @param segmentIndex: the index of the segment to query
    // @returns: list of latlng. Its length is written to length, which may not be nullptr
    // This list should be freed via FreeVertices
    EXPOSE const struct LatLngDart* GetAllVertices(const void* shape, int segmentIndex,
                                                   int* length);
    // Free result from GetAllVertices
    EXPOSE void FreeVertices(struct LatLngDart* vertices);
    // Get points lieing on a given side of the shape, so between begin and end of that side
    // It can either calculate how many points are needed based on the distance (specify
    // metersPerIntermiedatePoint) and write this number to numPoints or use a fixed amount (give
    // nullptr to numPoints and pass the requested number of points to meterPerIntermediatePoint)
    // @returns an array of points - free this via FreeIntermediatePoints
    EXPOSE struct LatLngDart* GetIntermediatePoints(const void* shape, int segIndex, int sideIndex,
                                                    double meterPerIntermediatePoint,
                                                    int* numPoints, int max, int min);
    // Free the output of GetIntermediatePoints
    EXPOSE void FreeIntermediatePoints(struct LatLngDart* points);

    // How many segments does the shape have?
    EXPOSE int GetNumberOfSegments(const void* shape);

    // How manu sides does this segment have?
    EXPOSE int GetNumberOfSidesInSegment(const void* shape, int segmentIndex);

    // ----section: Questions -----
    //
    // Is hider's latitude higher than yours?
    // @param latitude = your latitude
    EXPOSE void* LatitudeQuestion(void* shape, double latitude, int theirsHigher);
    // Is hider's longitude higher than yours?
    // This is actually answered by dividing the earth in half along the current longitude line,
    // instead of a higher longitude. Example: if longitude=180 then answering 'yes' to this
    // question means that the hider has '180 < longitude< -10'
    // @param longitude = your longitude
    EXPOSE void* LongitudeQuestion(void* shape, double longitude, int theirsHigher);

    // Is hider in the same administrative area as you
    // @params regions: an array of Shape* of length length that form all administrative areas
    // @param position: your position
    EXPOSE void* AdminAreaQuesiton(void* shape, void* regions, int length,
                                   struct LatLngDart position, int same);

    // Is hider within a circle centere at 'centre' of radius 'radius'
    EXPOSE void* WithinRadiusQuestion(void* shape, struct LatLngDart centre, double radius,
                                      int answer);

    EXPOSE void* UpdateBoundaryWithClosestToObject(void* boundary, struct LatLngDart closer,
                                                   struct LatLngDart further);
    // is hider's closest 'object' the same as yours?
    // @returns the new region where the hider could be based on this question
    // @params deleteFirst = should the input 'boundary' be deleted?
    EXPOSE void* UpdateBoundaryWithClosests(void* boundary, struct LatLngDart position,
                                            struct LatLngDart* objects, int numObjects, int answer,
                                            int deleteFirst);
    // ----section: querying other stuff
    EXPOSE double DistanceBetween(struct LatLngDart p1, struct LatLngDart p2);

    // Initialize and destruct everything, called when (un)loading the library
    // Do not call these anywhere else
    void InitEverything() __attribute__((constructor));
    void DestroyEverything() __attribute__((destructor));
#ifdef __cplusplus
}
#endif // __cplusplus
#endif // EXPOSE_H
