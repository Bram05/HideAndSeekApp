#include "Plane.h"
#include "Constants.h"
#include "Equations.h"
#include "Matrix3.h"
#include <stdexcept>
#include <vector>

Plane::Plane(Double a, Double b, Double c, Double d)
    : a(a)
    , b(b)
    , c(c)
    , d(d)
{
    if (!Vector3(a, b, c).length().close(1)) // normal must be normalized
    {
        throw std::runtime_error("Normal must be normalized!");
    }
}

Plane::Plane(const Vector3& normal, const Vector3& point)
    : a(normal.x)
    , b(normal.y)
    , c(normal.z)
    , d(dot(normal, point))
{
    if (!normal.length().close(1)) // normal must be normalized
    {
        throw std::runtime_error("Normal must be normalized!");
    }
}

Vector3 Plane::GetPointClosestToCentre() const
{
    // return getNormal().normalized() * d;
    return GetNormal() * d / GetNormal().length2();
}

Plane Plane::FromThreePoints(const Vector3& a, const Vector3& b, const Vector3& c)
{
    Vector3 d1  = a - b;
    Vector3 d2  = c - b;
    Vector3 res = NormalizedCrossProduct(d1, d2);
    return Plane(res, a);
}

Plane Plane::FromTwoPointsAndOrigin(const Vector3& a, const Vector3& b)
{
    Vector3 cross = NormalizedCrossProduct(a, b);
    return Plane(cross, Vector3(0, 0, 0));
}

// radius in metres
std::tuple<Plane, Vector3, Vector3> Plane::FromCircle(const Vector3& centre, const Double& radius,
                                                      bool clockwise)
{
    if (!(radius >= 0 && radius <= 0.5 * Constants::CircumferenceEarth + Constants::epsilon))
    {
        throw std::runtime_error(std::string("Invalid radius supplied: ") +
                                 std::to_string(radius.ToDouble()));
    }
    LatLng centreLatLng = centre.ToLatLng();
    Matrix3 rotation    = Matrix3::RotationX(
        -(0.5 * Constants::pi() -
          centreLatLng.latitudeInRad())); // the rotation is when viewing it along
                                             // the axis in the positive direction
    // print(vec3ToLatLng(rotation * Vector3(0, 0, radiusEarth)));
    rotation = Matrix3::RotationZ(centreLatLng.longitudeInRad()) * rotation;
    // print("rotated: ${vec3ToLatLng(rotation * Vector3(0, 0, radiusEarth))}");
    Double theta                     = 2 * Constants::pi() * radius / Constants::CircumferenceEarth;
    Matrix3 rotationWithTheta        = rotation * Matrix3::RotationY(theta);
    Matrix3 rotationWithThetaInverse = rotation * Matrix3::RotationY(-theta);
    // Matrix3 rotationWithTheta1 = rotation * Matrix3.rotationY(-theta);
    // Matrix3 rotationWithTheta2 = rotation * Matrix3.rotationX(theta);
    // Matrix3 rotationWithTheta3 = rotation * Matrix3.rotationX(-theta);
    Vector3 northPole            = Vector3(0, 0, 1);
    Vector3 pointOnPlane         = rotationWithTheta * northPole;
    Vector3 pointOnPlaneOpposite = rotationWithThetaInverse * northPole;
    // Vector3 pointOnPlane2 = rotationWithTheta1 * northPole;
    // Vector3 pointOnPlane3 = rotationWithTheta2 * northPole;
    // Vector3 pointOnPlane4 = rotationWithTheta3 * northPole;
    // Vector3 rotatedPointOnPlane = rotation * pointOnPlane;

    // print("test2: ${Matrix3.rotationY(theta) * northPole}");
    // print("test: ${vec3ToLatLng(Matrix3.rotationY(theta) * northPole)}");
    // print("point: ${vec3ToLatLng(pointOnPlane)}");
    // print("point: ${vec3ToLatLng(pointOnPlane2)}");
    // print("point: ${vec3ToLatLng(pointOnPlane3)}");
    // print("point: ${vec3ToLatLng(pointOnPlane4)}");
    // Vector3 normal = rotation * Vector3(0, 0, 1);
    // print("p = ${vec3ToLatLng(rotatedPointOnPlane)}");
    return { Plane(centre * (clockwise ? 1 : -1), pointOnPlane), pointOnPlane,
             pointOnPlaneOpposite };
}

bool Plane::LiesInside(const Vector3& point) const { return dot(GetNormal(), point).close(d); }

std::tuple<IntersectionType, std::optional<Line>> Intersect(const Plane& a, const Plane& b)
{
    Vector3 directionOfFinalLine = cross(a.GetNormal(), b.GetNormal());
    if (directionOfFinalLine.isZero())
    {
        // both planes are parallel
        if (a.GetPointClosestToCentre() == b.GetPointClosestToCentre())
        {
            // They are the same plane
            return { IntersectionType::coincide, std::nullopt };
        }
        return { IntersectionType::parallel, std::nullopt };
    }

    Vector3 directionInPlane1 = NormalizedCrossProduct(a.GetNormal(), directionOfFinalLine);
    Vector3 directionInPlane2 = NormalizedCrossProduct(b.GetNormal(), directionOfFinalLine);
    Line l1                   = Line(directionInPlane1, a.GetAPointOn());
    Line l2                   = Line(directionInPlane2, b.GetAPointOn());
    Vector3 pointOnLine       = Intersect(l1, l2);
    return { IntersectionType::normal, Line(directionOfFinalLine, pointOnLine) };
}

std::tuple<IntersectionType, std::vector<Vector3>> IntersectOnEarth(const Plane& a, const Plane& b)
{
    auto [type, l] = Intersect(a, b);
    if (type != IntersectionType::normal) { return { type, {} }; }
    Line line                = l.value();
    std::vector<Double> sols = SolveQuadratic(line.dir.length2(), 2 * dot(line.dir, line.point),
                                              // l.point.length2 - radiusEarth * radiusEarth,
                                              line.point.length2() - 1);
    // var ints                 = sols.map<Vector3>((double t) = > l.point + l.dir * t).toList();
    std::vector<Vector3> ints;
    for (const Double& t : sols) ints.push_back(line.point + line.dir * t);

    // print("IntersectOnEarth found ${ints.length} intersections: $ints");
    return { type, ints };
}

std::ostream& operator<<(std::ostream& os, const Plane& p)
{
    return os << p.a << ", " << p.b << ", " << p.c << ", " << p.d;
}
