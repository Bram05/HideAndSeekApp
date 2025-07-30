#pragma once

#include "Vector3.h"
#include <cassert>
class Line
{
public:
    Vector3 dir, point;

    Line(Vector3 dir, Vector3 point)
        : dir(dir)
        , point(point)
    {
        assert(!dir.isZero());
    }
};
Vector3 Intersect(const Line& l1, const Line& l2, const Vector3& perpendicular);
Vector3 Intersect(const Line& l1, const Line& l2);
