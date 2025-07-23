#pragma once

#include "Expose.h"
#define EXPOSE __attribute__((visibility("default")))
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

    struct Vector3Dart
    {
        double x, y, z;
    };

    EXPOSE int ConversionTestFromLatLng(struct LatLngDart point, int printInfo);
    EXPOSE int ConversionTestFromVec3(struct Vector3Dart point, int printInfo);
    EXPOSE int IntersectionTest(int printInfo);
    EXPOSE int CircleStraightTest(int printInfo);
    EXPOSE int CircleCircleTest(int printInfo);
    EXPOSE int PlaneTest(struct LatLngDart first, struct LatLngDart second,
                         struct Vector3Dart* normal, int printInfo);
    EXPOSE int CircleTest(struct LatLngDart centre, double radius, struct Vector3Dart* normal,
	    struct LatLngDart* points, int numPoints,
                          int printInfo);

    EXPOSE int TangentToLine(struct LatLngDart begin, struct LatLngDart end, struct Vector3Dart tangent, int printInfo);
    EXPOSE int TangentToCircle(struct LatLngDart centre, double radius, struct LatLngDart point, struct Vector3Dart tangent, int printInfo);
    EXPOSE int OneNonTransverseIntersection(struct LatLngDart s1, struct LatLngDart s2, struct LatLngDart s3, struct LatLngDart p1, struct LatLngDart p2, struct LatLngDart p3 , int printInfo);

#ifdef __cplusplus
}
#endif
