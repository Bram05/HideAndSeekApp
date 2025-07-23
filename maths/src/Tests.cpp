#include "Tests.h"
#include "Constants.h"
#include "Shape.h"
#include "Vector3.h"
#include <cstdio>
#include <locale>
#include <memory>

int ConversionTestFromLatLng(LatLngDart point, int printInfo)
{
    LatLng l = LatLng(point.lat, point.lon);
    if (printInfo) std::cerr << "l: " << l << '\n';
    Vector3 v = l.ToVector3();
    if (printInfo) std::cerr << v << '\n';
    LatLng res = v.ToLatLng();
    if (printInfo) std::cerr << res << '\n';
    return res == l;
}

int ConversionTestFromVec3(Vector3Dart point, int printInfo)
{
    Vector3 p = Vector3(point.x, point.y, point.z);
    if (printInfo) std::cerr << p << '\n';
    LatLng l = p.ToLatLng();
    if (printInfo) std::cerr << l << '\n';
    Vector3 res = l.ToVector3();
    if (printInfo) std::cerr << res << '\n';
    return res == p;
}
int IntersectionTest(int printInfo)
{
    Vector3 centre           = LatLng(0, 0).ToVector3();
    Plane p                  = std::get<0>(Plane::FromCircle(centre, 1000, true));
    std::shared_ptr<Side> s  = std::make_shared<CircleSide>(centre, 1000, 0, 3.14, p, true);
    std::shared_ptr<Side> s2 = std::make_shared<StraightSide>();
    auto result              = IntersectSides(*s.get(), *s2.get(), LatLng(0, 0.008983).ToVector3(),
                                              LatLng(0, -0.008983).ToVector3(), LatLng(0.3, 180).ToVector3(),
                                              LatLng(0, 0).ToVector3());
    if (result.size() != 1)
    {
        if (printInfo)
        {
            std::cerr << "Got result " << result << ". This failed because size is not correct.\n";
        }
        return 0;
    }
    if (result[0].point !=
        Vector3(-3.66702957743798e-18, 0.9999999877091389, 0.0001567855927765379))
    {
        if (printInfo)
        {
            std::cerr << "Got result " << result << ". This failed because point is not correct.\n";
        }
        return 0;
    }
    return 1;
}
int CircleStraightTest(int printInfo)
{
    Vector3 centre       = LatLng(0, 0).ToVector3();
    double radius        = 10000;
    auto [plane, p1, p2] = Plane::FromCircle(centre, radius, true);
    auto s1              = std::make_shared<CircleSide>(centre, radius, 0, 3.14, plane, true);
    auto s2              = std::make_shared<CircleSide>(centre, radius, 3.14, 3.14, plane, true);
    Shape shape1         = Shape({
        Segment({ p1, p2 }, { s1, s2 }),
    });
    Shape shape2         = Shape({
        Segment({ LatLng(0, 0).ToVector3(), LatLng(0.3, 180).ToVector3(),
                          LatLng(-0.3, 180).ToVector3() },
                        { std::make_shared<StraightSide>(), std::make_shared<StraightSide>(),
                          std::make_shared<StraightSide>() }),
    });
    auto result          = std::get<0>(IntersectionPoints(shape1, shape2));
    if (result.size() != 2)
    {
        if (printInfo) std::cerr << result << " is not correct because size is not 2\n";
        return 0;
    }
    if (result[0].point.ToLatLng() != LatLng(0.08983152770644671, 0) ||
        result[1].point.ToLatLng() != LatLng(-0.08983152770644671, 0))
    {
        if (printInfo)
            std::cerr
                << result
                << " is not correct because one of the points is not equal to what it should be\n";
        return 0;
    }
    return 1;
}

int CircleCircleTest(int printInfo)
{
    Vector3 centre           = LatLng(0, 0).ToVector3();
    double radius            = 10000;
    auto [plane, p1, p2]     = Plane::FromCircle(centre, radius, true);
    std::shared_ptr<Side> s1 = std::make_shared<CircleSide>(centre, radius, 0, 3.14, plane, true);
    std::shared_ptr<Side> s2 =
        std::make_shared<CircleSide>(centre, radius, 3.14, 3.14, plane, true);
    Shape shape1            = Shape({
        Segment({ p1, p2 }, { s1, s2 }),
    });
    centre                  = LatLng(0, -90).ToVector3();
    Double radiusD          = 0.25 * Constants::CircumferenceEarth;
    auto [plane2, p21, p22] = Plane::FromCircle(centre, radiusD, false);
    std::shared_ptr<CircleSide> s3 =
        std::make_shared<CircleSide>(centre, radiusD, 0, 3.14, plane2, false);
    std::shared_ptr<CircleSide> s4 =
        std::make_shared<CircleSide>(centre, radiusD, 3.14, 3.14, plane2, false);
    Shape shape2 = Shape({
        Segment({ p21, p22 }, { s3, s4 }),
    });
    auto result  = std::get<0>(IntersectionPoints(shape1, shape2));
    if (result.size() != 2)
    {
        if (printInfo) std::cerr << "Result " << result << " is not correct. Size is not 2\n";
        return 0;
    }
    if (result[0].point.ToLatLng() != LatLng(0.08983152770644671, 0) ||
        result[1].point.ToLatLng() != LatLng(-0.08983152770644671, 0))
    {
        // Our distance here is most likely correct, the online calculator used is less accurate
        // though
        if (printInfo)
            std::cerr
                << result
                << " is not correct because one of the points is not equal to what it should be\n";
        return 0;
    }
    return 1;
}

int PlaneTest(LatLngDart firstP, LatLngDart secondP, Vector3Dart* normalP, int printInfo)
{
    Vector3 begin = LatLng(firstP.lat, firstP.lon).ToVector3();
    Vector3 end   = LatLng(secondP.lat, secondP.lon).ToVector3();

    try
    {
        Plane p     = Plane::FromTwoPointsAndOrigin(begin, end);
        Plane p2    = Plane::FromTwoPointsAndOrigin(end, begin);
        bool first  = p.LiesInside(begin);
        bool second = p.LiesInside(end);
        bool third  = p2.LiesInside(begin);
        bool fourth = p2.LiesInside(end);
        if (!(first && second && third && fourth))
        {
            if (printInfo)
                std::cerr << "The booleans are: " << first << ", " << second << ", " << third
                          << ", " << fourth << '\n';
            return 0;
        }
        if (normalP != nullptr)
        {
            Vector3 normal = Vector3(normalP->x, normalP->y, normalP->z);
            if (p.GetNormal() != normal || p2.GetNormal() != -normal)
            {
                if (printInfo)
                    std::cerr << "Normal not correct: " << p.GetNormal() << "and " << p2.GetNormal()
                              << '\n';
                return 0;
            }
        }
    }
    catch (...)
    {
        return 2;
    }
    return 1;
}

int CircleTest(struct LatLngDart centreP, double radius, struct Vector3Dart* normalP,
               LatLngDart* points, int numPoints, int printInfo)
{
    Vector3 centre = LatLng(centreP.lat, centreP.lon).ToVector3();
    Plane p        = std::get<0>(Plane::FromCircle(centre, radius, true));
    for (int i = 0; i < numPoints; i++)
    {
        Vector3 point = LatLng(points[i].lat, points[i].lon).ToVector3();
        if (!p.LiesInside(point))
        {
            if (printInfo)
                std::cerr << "Point " << point << " does not lie inside the plane " << p << '\n';
            return 0;
        }
    }
    if (normalP)
    {
        Vector3 normal = Vector3(normalP->x, normalP->y, normalP->z);
        if (normal != p.GetNormal())
        {
            if (printInfo)
                std::cerr << "Normal " << p.GetNormal() << " is not correct for plane " << p
                          << "(should be " << normal << ")\n";
            return 0;
        }
    }
    return 1;
}

int TangentToLine(struct LatLngDart beginP, struct LatLngDart endP, struct Vector3Dart tangentP,
                  int printInfo)
{
    std::shared_ptr<Side> side = std::make_shared<StraightSide>();
    Vector3 begin              = LatLng(beginP.lat, beginP.lon).ToVector3();
    Vector3 end                = LatLng(endP.lat, endP.lon).ToVector3();
    Vector3 result             = Vector3(tangentP.x, tangentP.y, tangentP.z);
    Vector3 got                = side->getTangent(begin, end, begin);
    if (got != result)
    {
        if (printInfo)
            std::cerr << "Got result " << got << ", but should be " << result
                      << " for begin=" << begin << " and end=" << end << '\n';
        return 0;
    }
    return 1;
}

int TangentToCircle(struct LatLngDart centreP, double radius, struct LatLngDart pointP,
                    struct Vector3Dart tangentP, int printInfo)
{
    Vector3 centre             = LatLng(centreP.lat, centreP.lon).ToVector3();
    std::shared_ptr<Side> side = std::make_shared<CircleSide>(
        centre, radius, 0, 3.14, std::get<0>(Plane::FromCircle(centre, radius, true)), true);
    Vector3 begin   = LatLng(pointP.lat, pointP.lon).ToVector3();
    Vector3 got     = side->getTangent(begin, LatLng(0, 0).ToVector3(),
                                       begin); // Begin and end here shouldn't matter for a circle
    Vector3 tangent = Vector3(tangentP.x, tangentP.y, tangentP.z);
    if (got != tangent)
    {
        if (printInfo)
            std::cerr << "Wrong tangent, got " << got << " but should be " << tangent << '\n';
        return 0;
    }
    return 1;
}

int CheckShapesWithOneNonTransverseIntersections(const Shape& s1, const Shape& s2, int printInfo)
{
    auto [sol, _] = IntersectionPoints(s1, s2, false, false);
    if (sol.size() != 1)
    {
        if (printInfo) std::cerr << "Intersection shapes " << sol << " that should have length 1\n";
        return 0;
    }
    auto [sol2, _2] = IntersectionPoints(s2, s1);
    if (sol2.size() != 0)
    {
        if (printInfo)
            std::cerr << "Intersection shapes " << sol2 << " that should have length 0\n";
        return 0;
    }
    return 1;
}
int OneNonTransverseIntersection(struct LatLngDart s1, struct LatLngDart s2, struct LatLngDart s3,
                                 struct LatLngDart p1, struct LatLngDart p2, struct LatLngDart p3,
                                 int printInfo)
{
    std::shared_ptr<Side> side = std::make_shared<StraightSide>();
    Vector3 ps1                = LatLng(s1.lat, s1.lon).ToVector3();
    Vector3 ps2                = LatLng(s2.lat, s2.lon).ToVector3();
    Vector3 ps3                = LatLng(s3.lat, s3.lon).ToVector3();
    Vector3 pp1                = LatLng(p1.lat, p1.lon).ToVector3();
    Vector3 pp2                = LatLng(p2.lat, p2.lon).ToVector3();
    Vector3 pp3                = LatLng(p3.lat, p3.lon).ToVector3();

    Shape shape1 = Shape({ Segment({ ps1, ps2, ps3 }, { side, side, side }) });
    Shape shape2 = Shape({ Segment({ pp1, pp2, pp3 }, { side, side, side }) });
    if (CheckShapesWithOneNonTransverseIntersections(shape1, shape2, printInfo) != 1)
    {
        if (printInfo) std::cerr << "Intersection first two failed\n";
        return 0;
    }
    if (CheckShapesWithOneNonTransverseIntersections(shape2, shape1, printInfo) != 1)
    {
        if (printInfo) std::cerr << "Intersection second two failed\n";
        return 0;
    }
    return 1;
}
