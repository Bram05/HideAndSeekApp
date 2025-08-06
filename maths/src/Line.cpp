#include "Line.h"
Vector3 Intersect(const Line& l1, const Line& l2)
{
    Vector3 perpendicular = cross(l1.dir, l2.dir);
    return Intersect(l1, l2, perpendicular);
}
Vector3 Intersect(const Line& l1, const Line& l2, const Vector3& perpendicular)
{
    assert(!perpendicular.isZero());
    Vector3 perpendicularToLine1 = cross(l1.dir, perpendicular);
    Double constantForLine1      = dot(perpendicularToLine1, l1.point);
    Double t                     = (constantForLine1 - dot(l2.point, perpendicularToLine1)) /
               dot(l2.dir, perpendicularToLine1);
    return l2.point + l2.dir * t; // we have to use the other line here
}
