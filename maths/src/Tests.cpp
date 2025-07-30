#include "Tests.h"
#include "Constants.h"
#include "Expose.h"
#include "Shape.h"
#include "Vector3.h"
#include <cstdio>
#include <memory>
#include <tracy/Tracy.hpp>

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
    Vector3 p =
        Vector3(point.x, point.y, point.z)
            .normalized(); // The input not very precise (it is a normal double) so we MUST
                           // normalize again to get a point that is precise to a ton of digits
    if (printInfo) std::cerr << p << '\n';
    LatLng l = p.ToLatLng();
    if (printInfo) std::cerr << l << '\n';
    Vector3 res = l.ToVector3();
    if (printInfo) std::cerr << res << '\n';
    return res == p;
}
int IntersectionTest(int printInfo)
{
    Vector3 centre   = LatLng(0, 0).ToVector3();
    Double radius    = 1000;
    auto [p, p1, p2] = Plane::FromCircle(centre, radius, true);
    // std::cout << p << '\n';
    std::shared_ptr<Side> s = Side::HalfCircle(centre, 1000, true);
    std::shared_ptr<Side> s2 =
        Side::StraightSide(LatLng("0.3", "180").ToVector3(), LatLng(0, 0).ToVector3());
    auto result = IntersectSides(*s.get(), *s2.get());
    if (result.size() != 1)
    {
        if (printInfo)
        {
            std::cerr << "Got result " << result << ". This failed because size is not correct.\n";
        }
        return 0;
    }
    // if (result[0].point !=
    //     Vector3(-3.66702957743798e-18, 0.9999999877091389, 0.0001567855927765379))
    if (GetDistanceAlongEarth(result[0].point, centre) != 1000)
    {
        if (printInfo)
        {
            std::cerr << "Got result " << result
                      << ". This failed because point does not lie on the circle, distance: "
                      << GetDistanceAlongEarth(result[0].point, centre) << '\n';
        }
        return 0;
    }
    if (result[0].point.x != 0 || result[0].point.z <= 0)
    {
        if (printInfo)
        {
            std::cerr << "Got result " << result
                      << ". This failed because point does not lie on the straight lien.\n";
        }
        return 0;
    }
    return 1;
}
int CircleStraightTest(int printInfo)
{
    Vector3 centre = LatLng(0, 0).ToVector3();
    Double radius  = 10000;
    // auto [plane, p1, p2] = Plane::FromCircle(centre, radius, true);
    // auto s1              = std::make_shared<CircleSide>(centre, radius, plane, true);
    // auto s2              = std::make_shared<CircleSide>(centre, radius, plane, true);
    Shape shape1       = Side::FullCircle(centre, radius, true);
    Vector3 vertices[] = { LatLng(0, 0).ToVector3(), LatLng("0.3", 180).ToVector3(),
                           LatLng("-0.3", 180).ToVector3() };
    auto straight1     = Side::StraightSide(vertices[0], vertices[1]);
    auto straight2     = Side::StraightSide(vertices[1], vertices[2]);
    auto straight3     = Side::StraightSide(vertices[2], vertices[0]);
    Shape shape2       = Shape({
        Segment({ straight1, straight2, straight3 }),
    });
    auto result        = std::get<0>(IntersectionPoints(shape1, shape2));
    if (result.size() != 2)
    {
        if (printInfo) std::cerr << result << " is not correct because size is not 2\n";
        return 0;
    }
    auto IsPointValid = [&](const Vector3& p)
    {
        if (GetDistanceAlongEarth(p, centre) != radius)
        {
            if (printInfo)
                std::cerr << "Intersection " << p << " is not the correct distance from centre "
                          << centre << ". Distance =  " << GetDistanceAlongEarth(p, centre) << '\n';
            return false;
        }
        if (p.x != 0)
        {
            if (printInfo)
                std::cerr << "Intersection " << p << " does not lie on the plane with x=0!\n";
            return false;
        }
        return true;
    };
    if (!IsPointValid(result[0].point) || !IsPointValid(result[1].point))
    // if (result[0].point.ToLatLng() != LatLng(0.08983152770644671, 0) ||
    //     result[1].point.ToLatLng() != LatLng(-0.08983152770644671, 0))
    {
        return 0;
    }
    return 1;
}

int CircleCircleTest(int printInfo)
{
    Vector3 centre = LatLng(0, 0).ToVector3();
    double radius  = 10000;
    // auto [plane, p1, p2]           = Plane::FromCircle(centre, radius, true);
    // std::shared_ptr<Side> s1       = std::make_shared<CircleSide>(centre, radius, plane, true);
    // std::shared_ptr<Side> s2       = std::make_shared<CircleSide>(centre, radius, plane, true);
    Shape shape1    = Side::FullCircle(centre, radius, true);
    Vector3 centre2 = LatLng(0, -90).ToVector3();
    Double radius2  = 0.25 * Constants::CircumferenceEarth();
    // auto [plane2, p21, p22]        = Plane::FromCircle(centre2, radius2, false);
    // std::shared_ptr<CircleSide> s3 = std::make_shared<CircleSide>(centre2, radius2, plane2,
    // false); std::shared_ptr<CircleSide> s4 = std::make_shared<CircleSide>(centre2, radius2,
    // plane2, false);
    Shape shape2 = Side::FullCircle(centre2, radius2, true);
    auto result  = std::get<0>(IntersectionPoints(shape1, shape2));
    if (result.size() != 2)
    {
        if (printInfo) std::cerr << "Result " << result << " is not correct. Size is not 2\n";
        return 0;
    }
    // if (result[0].point.ToLatLng() != LatLng(0.08983152770644671, 0) ||
    //     result[1].point.ToLatLng() != LatLng(-0.08983152770644671, 0))
    if (GetDistanceAlongEarth(result[0].point, centre) != radius ||
        GetDistanceAlongEarth(result[1].point, centre) != radius ||
        GetDistanceAlongEarth(result[0].point, centre2) != radius2 ||
        GetDistanceAlongEarth(result[1].point, centre2) != radius2)
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
    Vector3 centre    = LatLng(centreP.lat, centreP.lon).ToVector3();
    Plane p           = std::get<0>(Plane::FromCircle(centre, radius, true));
    const Double prev = Constants::GetEpsilon(); // todo: maybe make this test better someday: don't
                                                 // rely on some points that were given
    Constants::SetEpsilon("1e-7");
    for (int i = 0; i < numPoints; i++)
    {
        Vector3 point = LatLng(points[i].lat, points[i].lon).ToVector3();
        if (!p.LiesInside(point))
        {
            if (printInfo)
                std::cerr << "Point " << point << " does not lie inside the plane " << p << '\n';
            Constants::SetEpsilon(prev);
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
            Constants::SetEpsilon(prev);
            return 0;
        }
    }
    Constants::SetEpsilon(prev);
    return 1;
}

int TangentToLine(struct LatLngDart beginP, struct LatLngDart endP, struct Vector3Dart tangentP,
                  int printInfo, int reducePrecision)
{
    // std::shared_ptr<Side> side = std::make_shared<StraightSide>();
    Vector3 begin  = LatLng(beginP.lat, beginP.lon).ToVector3();
    Vector3 end    = LatLng(endP.lat, endP.lon).ToVector3();
    Vector3 result = Vector3(tangentP.x, tangentP.y, tangentP.z);
    auto side      = Side::StraightSide(begin, end);
    Vector3 got    = side->getTangent(begin);
    auto prev      = Constants::GetEpsilon();
    Constants::SetEpsilon(Double("1e-7"));
    if (got != result)
    {
        if (printInfo)
            std::cerr << "Got result " << got << ", but should be " << result
                      << " for begin=" << begin << " and end=" << end << '\n';
        Constants::SetEpsilon(prev);
        return 0;
    }
    Constants::SetEpsilon(prev);
    return 1;
}

int TangentToCircle(struct LatLngDart centreP, double radius, struct LatLngDart pointP,
                    struct Vector3Dart tangentP, int printInfo)
{
    Vector3 centre = LatLng(centreP.lat, centreP.lon).ToVector3();
    // std::shared_ptr<Side> side = std::make_shared<CircleSide>(centre, radius, true);
    auto side     = Side::HalfCircle(centre, radius, true);
    Vector3 begin = LatLng(pointP.lat, pointP.lon).ToVector3();
    auto prev     = Constants::GetEpsilon();
    Constants::SetEpsilon("1e-6"); // The pointP may not lie exactly on the circle and
                                   // assertion in side->getTangent therefore fails
    Vector3 got = side->getTangent(begin);
    Constants::SetEpsilon(prev);
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
    ZoneScoped;
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
    ZoneScoped;
    // std::shared_ptr<Side> side = std::make_shared<StraightSide>();
    Vector3 ps1 = LatLng(s1.lat, s1.lon).ToVector3();
    Vector3 ps2 = LatLng(s2.lat, s2.lon).ToVector3();
    Vector3 ps3 = LatLng(s3.lat, s3.lon).ToVector3();
    Vector3 pp1 = LatLng(p1.lat, p1.lon).ToVector3();
    Vector3 pp2 = LatLng(p2.lat, p2.lon).ToVector3();
    Vector3 pp3 = LatLng(p3.lat, p3.lon).ToVector3();
    auto side1  = Side::StraightSide(ps1, ps2);
    auto side2  = Side::StraightSide(ps2, ps3);
    auto side3  = Side::StraightSide(ps3, ps1);
    auto tside1 = Side::StraightSide(pp1, pp2);
    auto tside2 = Side::StraightSide(pp2, pp3);
    auto tside3 = Side::StraightSide(pp3, pp1);

    Shape shape1 = Shape({ Segment({ side1, side2, side3 }) });
    Shape shape2 = Shape({ Segment({ tside1, tside2, tside3 }) });
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
bool VerifyPoints(const Plane& p, const Vector3& begin, const Vector3& centre, const Vector3& end,
                  LatLngDart* points, int number, int printInfo)
{
    // Neede because of conversion to LatLngDart
    auto prev = Constants::GetEpsilon();
    Constants::SetEpsilon("1e-7");
    for (int i = 0; i < number; i++)
    {
        Vector3 point = LatLng(points[i].lat, points[i].lon).ToVector3();
        if (!vec3LiesBetween(point, begin, end, p, centre) && point != end)
        { // Vec3liesbetween ignores the end
            if (printInfo)
                std::cerr << "Point with index " << i << ": " << point.ToLatLng()
                          << " does not lie between the begin and end (delta = " << (point - begin)
                          << ")\n";
            Constants::SetEpsilon(prev);
            return false;
        }
        if (GetDistanceAlongEarth(point, centre) != GetDistanceAlongEarth(begin, centre))
        {
            if (printInfo)
                std::cerr << "Distance of point " << point << " (index " << i
                          << ") is not correct: dist of point="
                          << GetDistanceAlongEarth(begin, centre)
                          << " and dist of begin=" << GetDistanceAlongEarth(begin, centre) << '\n';
            Constants::SetEpsilon(prev);
            return false;
        }
    }
    Constants::SetEpsilon(prev);
    return true;
}
bool CheckShape(const Shape& shape, int number, int printInfo)
{
    for (int j = 0; j < shape.segments.size(); j++)
    {
        const Segment& s = shape.segments[j];
        for (int i = 0; i < s.sides.size(); i++)
        {
            const Vector3& begin = s.sides[i]->begin;
            const Vector3& end   = s.sides[i]->end;
            LatLngDart* points   = GetIntermediatePoints(&shape, j, i, number);
            if (!VerifyPoints(s.sides[i]->plane, begin, s.sides[i]->properCentre, end, points,
                              number, printInfo))
            {
                if (printInfo)
                    std::cerr << "Side " << i << " in segment " << j << " failed for " << number
                              << " points\n";
                return false;
            }
            FreeIntermediatePoints(points);
        }
    }
    return true;
}
int IntermediatePointsTest(int printInfo)
{
    // std::shared_ptr<Side> straightSide = std::make_shared<StraightSide>();
    Vector3 vertices[]            = { LatLng(0, 0).ToVector3(), LatLng("0.3", 180).ToVector3(),
                                      LatLng("-0.3", 180).ToVector3() };
    std::shared_ptr<Side> sides[] = { Side::StraightSide(vertices[0], vertices[1]),
                                      Side::StraightSide(vertices[1], vertices[2]),
                                      Side::StraightSide(vertices[2], vertices[0]) };
    Vector3 centre                = LatLng(-53, 10).ToVector3();
    Double radius                 = 10;
    Shape shape                   = Side::FullCircle(centre, radius, true);
    shape.segments.push_back(Segment({ sides[0], sides[1], sides[2] }));

    // Shape shape                   = Shape({ Segment({ sides[0], sides[1], sides[2] }),
    //
    //                                         Segment({ circle1, circle2 }) });
    return CheckShape(shape, 2, printInfo) &&

           CheckShape(shape, 100, printInfo) && CheckShape(shape, 1000, printInfo);
}
